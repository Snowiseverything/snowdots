#!/usr/bin/env python3
"""RGB Bridge — REST API for OpenRGB + MAD68 keyboard.

Controls OpenRGB and MAD68 keyboard over HTTP so Home Assistant
and other clients can set colors without direct hardware access.

Port: 5070

Endpoints:
  GET  /status                    — current state of all devices + system metrics
  GET  /metrics                   — system metrics (CPU, GPU, RAM, disk, network)
  GET  /wallpapers                — list available wallpaper files
  GET  /ws                        — WebSocket for real-time state updates (port 5071)
  POST /openrgb                   — set OpenRGB color
  POST /keyboard                  — set MAD68 keyboard color
  POST /all                       — set all devices at once
  POST /sync                      — trigger rgb-sync.sh (wallpaper colors)
  POST /power                     — {"action": "suspend"|"reboot"|"shutdown"} (safe: add "dry_run": true to validate)
  POST /wallpaper                 — trigger wall-sync.sh (re-apply current wallpaper + colors)
  POST /wallpaper/set             — set wallpaper by filename (e.g. {"name": "wallpaper.jpg"})
  GET  /ping                      — health check

Body format (JSON):
  {"color": "ff0000"}             — hex color, no #
  {"color": "ff0000", "brightness": 50}  — 0-100

Example:
  curl -X POST http://localhost:5070/all -d '{"color":"ff0000","brightness":50}'
"""

import json, os, re, subprocess, sys, threading, time, socket as _socket
from http.server import HTTPServer, BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from pathlib import Path as _Path

# ── Config ────────────────────────────────────────────────────────────────
sys.path.insert(0, str(Path.home() / ".local/bin"))
try:
    from rgb_config import load_config, config_value  # pyright: ignore[reportMissingImports]
    _CFG = load_config()
except Exception:
    _CFG = None
    config_value = None  # type: ignore[assignment]


def _cfg(key, default):
    if _CFG is None or config_value is None:
        return default
    keys = key.split(".")
    return config_value(_CFG, *keys, default=default)


def _safe_int(v, default=0):
    """int() with fallback — config/file values can be malformed."""
    try:
        return int(v)
    except (TypeError, ValueError, OverflowError):
        return default


PORT = _safe_int(_cfg("server.port", 5070), 5070)
WS_PORT = _safe_int(_cfg("server.ws_port", 5071), 5071)
MAD68_SCRIPT = _Path.home() / ".local/bin/mad68-rgb.py"
MAD68_OFF_SCRIPT = Path.home() / ".local/bin/mad68-off.py"
SYNC_SCRIPT = Path.home() / "Dotfiles/scripts/rgb-sync.sh"
WALL_SYNC_SCRIPT = Path.home() / "Dotfiles/scripts/wall-sync.sh"
GOVEE_SCRIPT = Path.home() / "Dotfiles/scripts/govee-led.py"


# ── State tracking ──────────────────────────────────────────────────────
def current_wallpaper_name() -> str:
    cache_file = Path.home() / ".cache/skwd-wall/last_applied_wall.txt"
    if cache_file.exists():
        return cache_file.read_text().strip().split("/")[-1] or "none"
    return "none"

def current_wallpaper_path() -> str | None:
    cache_file = Path.home() / ".cache/skwd-wall/last_applied_wall.txt"
    if cache_file.exists():
        path = cache_file.read_text().strip()
        return path if path and Path(path).exists() else None
    return None


_DEF_BRI = _safe_int(_cfg("brightness.default", 80), 80)
_DEF_KB_BRI = _safe_int(_cfg("brightness.keyboard", 80), 80)

state = {
    "openrgb": {"color": "000000", "brightness": _DEF_BRI, "mode": "static"},
    "keyboard": {"color": "000000", "brightness": _DEF_KB_BRI},
    "govee": {"color": "000000", "brightness": _DEF_BRI},
    "last_color": "000000",
    "restore_color": "00dbeb",
    # Last non-zero brightness per device — used to wake a device from off
    # on sync instead of resetting to a fixed 80. Updated only when a
    # brightness > 0 is applied.
    "restore_brightness": {"openrgb": _DEF_BRI, "keyboard": _DEF_KB_BRI, "govee": _DEF_BRI},
    "synced": False,
    "last_sync": None,
    "wallpaper": current_wallpaper_name(),
}

# ── State persistence ────────────────────────────────────────────────────
# Bridge state is in-memory only by default, so a restart (or a suspend/
# wake cycle that reinitializes hardware) would forget the last color and
# per-device brightness, resetting syncs to the 80% default. Persist the
# color + brightness to a cache file and reload on startup.
_STATE_FILE = Path.home() / ".cache/rgb-bridge-state.json"


def _save_state():
    """Persist color/brightness state to cache file."""
    try:
        payload = {
            "openrgb": dict(state.get("openrgb", {})),
            "keyboard": dict(state.get("keyboard", {})),
            "govee": dict(state.get("govee", {})),
            "last_color": state.get("last_color", "000000"),
            "restore_color": state.get("restore_color", "00dbeb"),
            "restore_brightness": dict(state.get("restore_brightness", {})),
        }
        _STATE_FILE.write_text(json.dumps(payload))
    except Exception as e:
        print(f"State save failed: {e}", file=sys.stderr)


def _load_state():
    """Load persisted color/brightness state from cache file."""
    try:
        if not _STATE_FILE.exists():
            return
        data = json.loads(_STATE_FILE.read_text())
        for key in ("last_color", "restore_color"):
            if key in data and data[key]:
                state[key] = data[key]
        for device in ("openrgb", "keyboard", "govee"):
            if device in data and isinstance(data[device], dict):
                d = data[device]
                if "color" in d and d["color"]:
                    state[device]["color"] = d["color"]
                if "brightness" in d:
                    try:
                        state[device]["brightness"] = int(d["brightness"])
                    except (TypeError, ValueError):
                        pass
        if isinstance(data.get("restore_brightness"), dict):
            for k, v in data["restore_brightness"].items():
                if k in state["restore_brightness"]:
                    try:
                        state["restore_brightness"][k] = int(v)
                    except (TypeError, ValueError):
                        pass
        print(f"State loaded: last=#{state['last_color']} bri={state['restore_brightness']}", file=sys.stderr)
    except Exception as e:
        print(f"State load failed: {e}", file=sys.stderr)


_load_state()


def _kill_inflight_fades():
    """Kill running fade processes so an off/set doesn't race them.

    fade-rgb.py + govee-led.py --fade animate over ~0.6s in threads;
    an All Off issued mid-fade gets overwritten by later frames — the
    RAM flash the user saw. Kill first, then apply the new state.
    """
    for pat in ("fade-rgb.py", "govee-led.py"):
        try:
            subprocess.run(["pkill", "-f", pat], capture_output=True)
        except Exception:
            pass


def set_openrgb(color: str, brightness: int | None = None):
    """Set all OpenRGB devices via SDK in Direct mode (per-LED color)."""
    if brightness is None:
        brightness = _safe_int(_cfg("brightness.default", 80), 80)
    if not _cfg("devices.openrgb", True):
        return True
    r, g, b = [int(color[i:i+2], 16) for i in (0, 2, 4)]
    factor = max(0, min(100, brightness)) / 100.0
    ri, gi, bi = round(r * factor), round(g * factor), round(b * factor)

    # Wait for the OpenRGB server to be *protocol-ready*. A raw TCP connect
    # is NOT enough — the server's device enumeration runs for seconds after
    # the listen socket opens, and connecting-and-closing without speaking
    # the protocol is exactly what makes OpenRGB's server SEGV ("recv_select
    # failed receiving magic"). So we probe with a real handshake: send the
    # ORGB magic + protocol-version request and wait for a reply, retrying
    # with backoff until the server answers properly.
    import socket, time
    host = _cfg("openrgb.host", "localhost")
    port = _safe_int(_cfg("openrgb.port", 6742), 6742)
    ok = False
    for _attempt in range(6):
        try:
            s = socket.create_connection((host, port), timeout=2)
            try:
                # OpenRGB protocol: 16-byte header, magic "ORGB", then
                # packet type 40 = REQUEST_PROTOCOL_VERSION, size 4.
                import struct
                header = struct.pack("ccccIII", b"O", b"R", b"G", b"B", 0, 40, 4)
                s.sendall(header)
                s.sendall(struct.pack("I", 4))
                # Server replies with a header; any bytes received proves the
                # protocol layer is up (device enumeration finished).
                s.settimeout(2)
                resp = s.recv(16)
                if len(resp) >= 16:
                    ok = True
                    break
            finally:
                s.close()
        except OSError:
            pass
        time.sleep(1.0)
    if not ok:
        print(f"OpenRGB: server not protocol-ready on {host}:{port}", file=sys.stderr)
        return False

    try:
        from openrgb import OpenRGBClient
        from openrgb.utils import RGBColor
        orgb = OpenRGBClient(host, port, name="rgb-bridge")
        for d in orgb.devices:
            if ri == gi == bi == 0 and d.active_mode != 1:
                # Off — switch to Off mode so LEDs truly turn off
                d.set_mode(1)
            else:
                # Direct mode — per-LED colors work on all devices
                if d.active_mode != 0:
                    d.set_mode(0)
                d.set_colors([RGBColor(ri, gi, bi)] * len(d.leds))
                d.show()
        orgb.disconnect()
        state["openrgb"] = {"color": color, "brightness": brightness, "mode": "direct"}
        state["last_color"] = color
        if brightness > 0:
            state["restore_brightness"]["openrgb"] = brightness
        _save_state()
        return True
    except Exception as e:
        print(f"OpenRGB error: {e}", file=sys.stderr)
        # Fallback to CLI
        try:
            from pathlib import Path
            subprocess.run(
                ["openrgb", "--mode", "direct", "--color", "%02x%02x%02x" % (ri, gi, bi)],
                timeout=5, capture_output=True,
            )
            state["openrgb"] = {"color": color, "brightness": brightness, "mode": "direct"}
            state["last_color"] = color
            if brightness > 0:
                state["restore_brightness"]["openrgb"] = brightness
            _save_state()
            return True
        except Exception as e2:
            print(f"OpenRGB CLI fallback error: {e2}", file=sys.stderr)
            return False


def set_keyboard(color: str, brightness: int | None = None):
    """Set MAD68 keyboard color via HID.

    Sends raw (undimmed) color with brightness byte for hardware dimming.
    This preserves color balance — pre-dimmed RGB shifts LED color temp.
    """
    if brightness is None:
        brightness = _safe_int(_cfg("brightness.keyboard", 80), 80)
    if not _cfg("devices.keyboard", True):
        return True
    try:
        subprocess.run(
            [sys.executable, str(MAD68_SCRIPT), color, str(brightness)],
            timeout=5, capture_output=True,
        )
        state["keyboard"] = {"color": color, "brightness": max(brightness, 1)}
        state["last_color"] = color
        if brightness > 0:
            state["restore_brightness"]["keyboard"] = brightness
        _save_state()
        return True
    except Exception as e:
        print(f"Keyboard error: {e}", file=sys.stderr)
        return False


def set_keyboard_off():
    """Turn off MAD68 keyboard LEDs using per-slot black protocol."""
    try:
        subprocess.run(
            [sys.executable, str(MAD68_OFF_SCRIPT)],
            timeout=5, capture_output=True,
        )
        state["keyboard"] = {"color": "000000", "brightness": 0}
        _save_state()
        return True
    except Exception as e:
        print(f"Keyboard off error: {e}", file=sys.stderr)
        return False


def set_govee(color: str, brightness: int | None = None):
    """Set Govee LED strip via HA API or direct BLE."""
    if brightness is None:
        brightness = _safe_int(_cfg("brightness.default", 80), 80)
    if not _cfg("devices.govee", True):
        return True
    try:
        subprocess.run(
            [sys.executable, str(GOVEE_SCRIPT), color, str(brightness)],
            timeout=10, capture_output=True,
        )
        state["govee"] = {"color": color, "brightness": brightness}
        state["last_color"] = color
        if brightness > 0:
            state["restore_brightness"]["govee"] = brightness
        _save_state()
        return True
    except Exception as e:
        print(f"Govee error: {e}", file=sys.stderr)
        return False


WALLPAPER_DIR = Path.home() / "Pictures/Wallpapers"


def list_wallpapers() -> list[str]:
    """List all wallpaper files (including subdirectories like effects/)."""
    if not WALLPAPER_DIR.exists():
        return []
    valid_ext = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
    wallpapers = []
    try:
        for entry in sorted(WALLPAPER_DIR.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
            if entry.is_file() and entry.suffix.lower() in valid_ext:
                wallpapers.append(entry.name)
        for subdir in sorted(WALLPAPER_DIR.iterdir()):
            if subdir.is_dir() and not subdir.name.startswith("."):
                for entry in sorted(subdir.iterdir(), key=lambda p: p.stat().st_mtime, reverse=True):
                    if entry.is_file() and entry.suffix.lower() in valid_ext:
                        wallpapers.append(f"{subdir.name}/{entry.name}")
    except Exception:
        pass
    return wallpapers


def set_wallpaper(name: str) -> bool:
    """Set a specific wallpaper by filename and run wall-sync.sh."""
    path = WALLPAPER_DIR / name
    if not path.exists():
        return False
    cache_dir = Path.home() / ".cache/skwd-wall"
    cache_dir.mkdir(parents=True, exist_ok=True)
    (cache_dir / "last_applied_wall.txt").write_text(str(path))
    ok = trigger_wallpaper(wallpaper_path=str(path))
    state["wallpaper"] = name
    return ok


def trigger_wallpaper(wallpaper_path: str | None = None):
    """Run wall-sync.sh to apply wallpaper and refresh colors.
    
    Args:
        wallpaper_path: Path to the wallpaper to apply. If None, wall-sync.sh
                        will auto-detect from the cache file.
    """
    try:
        cmd = ["bash", str(WALL_SYNC_SCRIPT)]
        if wallpaper_path:
            cmd.append(wallpaper_path)
        subprocess.run(cmd, timeout=60, capture_output=True)
        state["wallpaper"] = current_wallpaper_name()
        return True
    except Exception as e:
        print(f"Wallpaper error: {e}", file=sys.stderr)
        return False


def _compute_color() -> str:
    """Read wallpaper accent and compute unified LED color."""
    import colorsys, json as _json
    colors_file = Path.home() / ".cache/skwd-wall/colors.json"
    if not colors_file.exists():
        return "000000"
    try:
        data = _json.loads(colors_file.read_text())
        accent = data.get("accent", "#000000").lstrip("#")
        r, g, b = int(accent[0:2], 16) / 255.0, int(accent[2:4], 16) / 255.0, int(accent[4:6], 16) / 255.0
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        rl, gl, bl = colorsys.hls_to_rgb(h, 0.45, 0.90)
        return '%02x%02x%02x' % (int(rl * 255), int(gl * 255), int(bl * 255))
    except Exception:
        return "000000"


def _recall_restore(bri, kb_bri, govee_bri):
    """Wake each device that is at brightness 0 back to its last non-zero value."""
    if bri == 0:
        bri = state.get("restore_brightness", {}).get("openrgb", 80)
    if kb_bri == 0:
        kb_bri = state.get("restore_brightness", {}).get("keyboard", 80)
    if govee_bri == 0:
        govee_bri = state.get("restore_brightness", {}).get("govee", 80)
    return bri, kb_bri, govee_bri


def trigger_sync():
    """Sync PC devices + Govee. Returns dict with ok + message.

    Sync ALWAYS runs (fade-rgb.py handles skip-if-same internally).
    The response message tells the caller whether this was a fresh sync
    or the color hadn't changed since the last bridge call.
    """
    color = _compute_color()
    if color == "000000":
        return {"ok": False, "message": "No accent color"}

    # Decide message BEFORE the sync: "Already synced" if color unchanged
    already_synced = color == state.get("last_color")
    message = "Already synced to wallpaper" if already_synced else "Colors synced to wallpaper"

    bri = state["openrgb"].get("brightness", 80)
    kb_bri = state["keyboard"].get("brightness", 80)
    govee_bri = state["govee"].get("brightness", 80)
    # Wake any device that is currently off so wallpaper sync brings the
    # lights back, but at its LAST brightness — not a fixed 80. A device
    # that is intentionally on keeps its brightness; only off→on wakes.
    bri, kb_bri, govee_bri = _recall_restore(bri, kb_bri, govee_bri)
    # mad68 hardware off is brightness-byte 0; clamp the wake target so a
    # restored value of 0 (edge case) still renders a lit keyboard.
    kb_dim = max(kb_bri, 1)

    def _govee_async(c):
        try:
            subprocess.run(
                [sys.executable, str(GOVEE_SCRIPT), c, str(govee_bri)],
                timeout=15, capture_output=True,
            )
            state["govee"]["color"] = c
            state["govee"]["brightness"] = govee_bri
        except Exception:
            pass

    try:
        state["synced"] = True
        t_govee = threading.Thread(target=_govee_async, args=(color,), daemon=True)
        t_govee.start()
        # PC devices via fade-rgb.py (crossfade, ~0.6s) — pass keyboard's
        # own brightness (kb_dim) so it doesn't get reset to the PC value.
        # pc_brightness=bri (>0 after the wake above); fade-rgb still guards
        # bri 0 defensively in case it's called directly at zero.
        result = subprocess.run(
            [sys.executable, str(Path.home() / "Dotfiles/scripts/fade-rgb.py"), color, str(bri), str(kb_dim)],
            timeout=10, capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"fade-rgb stderr: {result.stderr}", file=sys.stderr)
        state["openrgb"]["color"] = color
        state["openrgb"]["brightness"] = bri
        state["openrgb"]["mode"] = "direct"
        state["keyboard"]["color"] = color
        state["keyboard"]["brightness"] = kb_dim
        state["restore_color"] = color
        state["last_color"] = color
        _save_state()
        return {"ok": True, "message": message}
    except Exception as e:
        print(f"Sync error: {e}", file=sys.stderr)
        return {"ok": False, "message": f"Sync error: {e}"}


def parse_color(body: dict) -> str | None:
    """Extract hex color from request body."""
    color = body.get("color", "")
    return color.lstrip("#") if color else None


def track_color(hex_color: str):
    """Save recently used colors to cache file."""
    cache = Path.home() / ".cache/rgb-colors.json"
    colors = []
    try:
        if cache.exists():
            colors = json.loads(cache.read_text())
    except Exception:
        pass
    if hex_color == "000000":
        return
    color = hex_color.lstrip("#")
    if len(color) != 6:
        return
    color = "#" + color
    if color in colors:
        colors.remove(color)
    colors.insert(0, color)
    colors = colors[:6]
    try:
        cache.write_text(json.dumps(colors))
    except Exception:
        pass


# ── System metrics ───────────────────────────────────────────────────────
def get_system_metrics() -> dict:
    """Collect system metrics for HA monitoring.

    Returns CPU temp, GPU temp, utilization, memory, disk, network.
    Uses lm-sensors (sensors) and nvidia-smi when available.
    """
    metrics = {
        "hostname": "freezer",
        "timestamp": time.time(),
        "cpu": {},
        "gpu": {},
        "memory": {},
        "disk": {},
        "network": {},
    }

    # CPU temp + fans via lm-sensors
    try:
        out = subprocess.run(["sensors", "-j"], capture_output=True, text=True, timeout=5).stdout
        data = json.loads(out)
        for chip, chip_data in data.items():
            if not isinstance(chip_data, dict):
                continue
            # coretemp: "Package id 0" -> {"temp1_input": 31.0}
            # nct6798: "temp1" -> {"temp1_input": 39.0}
            for k, v in chip_data.items():
                if not isinstance(v, dict):
                    continue
                # Look for *_input keys in nested dicts
                for nk, nv in v.items():
                    if isinstance(nv, (int, float)) and nk.endswith("_input"):
                        label = nk.replace("_input", "")
                        if "temp" in label:
                            # Package temp or core temps
                            if k == "Package id 0":
                                metrics["cpu"]["package_temp"] = nv
                            elif "Core" in k:
                                core_num = k.replace("Core ", "")
                                metrics["cpu"][f"core_{core_num}_temp"] = nv
                            elif "SYSTIN" in k:
                                metrics["cpu"]["systin"] = nv
                            elif "CPUTIN" in k:
                                metrics["cpu"]["cputin"] = nv
                            elif label == "temp1":
                                if "nct6798" in chip:
                                    metrics["cpu"]["motherboard_temp"] = nv
                            else:
                                metrics["cpu"][f"temp_{label}"] = nv
                        elif "fan" in label:
                            metrics["cpu"][f"fan_{label}"] = nv
    except Exception:
        pass

    # GPU via nvidia-smi
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw,name",
             "--format=csv,noheader"],
            capture_output=True, text=True, timeout=5
        ).stdout.strip()
        if out:
            parts = [p.strip() for p in out.split(",")]
            metrics["gpu"] = {
                "temp": int(parts[0]),
                "utilization": int(parts[1].replace("%", "").strip()),
                "memory_used_mb": int(parts[2].replace("MiB", "").strip()),
                "memory_total_mb": int(parts[3].replace("MiB", "").strip()),
                "power_watts": float(parts[4].replace("W", "").strip()) if "Not Support" not in parts[4] else None,
                "name": parts[5],
            }
    except Exception:
        pass

    # CPU load average
    try:
        with open("/proc/loadavg") as f:
            parts = f.read().strip().split()
            metrics["cpu"]["load_1"] = float(parts[0])
            metrics["cpu"]["load_5"] = float(parts[1])
            metrics["cpu"]["load_15"] = float(parts[2])
    except Exception:
        pass

    # CPU usage
    try:
        out = subprocess.run(["mpstat", "1", "1"], capture_output=True, text=True, timeout=5).stdout
        for line in out.splitlines():
            if "Average:" in line or "%idle" in line:
                idle = line.split("%idle")[-1].strip() if "%idle" in line else "0"
                # This is a rough parse; mpstat format varies
                metrics["cpu"]["usage_percent"] = 100.0 - float(idle) if idle else None
                break
    except Exception:
        pass

    # Memory
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    metrics["memory"]["total_kb"] = int(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    metrics["memory"]["available_kb"] = int(line.split()[1])
                elif line.startswith("MemFree:"):
                    metrics["memory"]["free_kb"] = int(line.split()[1])
    except Exception:
        pass

    # Disk usage (root)
    try:
        st = os.statvfs("/")
        metrics["disk"]["total_bytes"] = st.f_blocks * st.f_frsize
        metrics["disk"]["available_bytes"] = st.f_bavail * st.f_frsize
    except Exception:
        pass

    # Network — enp6s0
    try:
        with open("/proc/net/dev") as f:
            for line in f:
                if "enp6s0" in line:
                    parts = line.split()
                    rx_bytes = int(parts[1])
                    tx_bytes = int(parts[9])
                    metrics["network"]["rx_bytes"] = rx_bytes
                    metrics["network"]["tx_bytes"] = tx_bytes
                    break
    except Exception:
        pass

    # Uptime
    try:
        with open("/proc/uptime") as f:
            metrics["uptime_seconds"] = float(f.read().split()[0])
    except Exception:
        pass

    return metrics


# ── WebSocket broadcaster ────────────────────────────────────────────────
_ws_clients: list = []


def _broadcast_state():
    """Push current state + metrics to all WebSocket clients."""
    payload = json.dumps({"type": "update", "state": state, "metrics": get_system_metrics()})
    for ws in list(_ws_clients):
        try:
            ws.send(payload)
        except Exception:
            _ws_clients.remove(ws)


def _ws_handler(ws):
    """Handle a WebSocket connection."""
    # Handshake done by WebSocketServer; just track and subscribe
    _ws_clients.append(ws)


# ── HTTP Handler ─────────────────────────────────────────────────────────
class RGBHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # suppress default logging

    def _json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "http://localhost")
        self.send_header("Access-Control-Allow-Credentials", "true")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def _body(self) -> dict:
        length = _safe_int(self.headers.get("Content-Length", 0), 0)
        if length == 0:
            return {}
        try:
            return json.loads(self.rfile.read(length))
        except (ValueError, OSError):
            return {}

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "http://localhost")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        # Strip query string (?v=...) — HA appends a cache-busting query to the case SVG URL
        path = self.path.split("?", 1)[0]
        if path in ("/status", "/current"):
            self._json({**state, "metrics": get_system_metrics()})
        elif path == "/metrics":
            self._json(get_system_metrics())
        elif path == "/ping":
            self._json({"status": "ok"})
        elif path == "/wallpapers":
            names = list_wallpapers()
            self._json({
                "wallpapers": names,
                "wallpapers_detailed": [
                    {"name": n, "thumbnail": f"http://localhost:5070/wallpaper/image/{n}"}
                    for n in names
                ]
            })
        elif path.startswith("/wallpaper/image/"):
            name = path.split("/wallpaper/image/")[-1]
            self._serve_wallpaper_image(name)
        elif path == "/recent":
            self._json_recent()
        elif path == "/case.svg":
            self._serve_case_svg()
        elif path == "/" or path == "/dashboard":
            self._serve_html()
        else:
            self._json({"error": "not found"}, 404)

    def _serve_wallpaper_image(self, name: str):
        """Serve a wallpaper image file for HA thumbnails."""
        path = WALLPAPER_DIR / name
        if not path.exists() or not path.is_file():
            self._json({"error": "not found", "name": name}, 404)
            return
        ext = path.suffix.lower()
        mime = {
            ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
            ".png": "image/png", ".gif": "image/gif",
            ".webp": "image/webp",
        }.get(ext, "application/octet-stream")
        try:
            data = path.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", mime)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "max-age=3600")
            self.end_headers()
            self.wfile.write(data)
        except Exception as e:
            self._json({"error": str(e)}, 500)

    def _json_recent(self):
        cache = Path.home() / ".cache/rgb-colors.json"
        colors = ["#ff6600", "#00aaff", "#ff0066", "#00ff88", "#ffaa00", "#aa00ff"]
        try:
            if cache.exists():
                colors = json.loads(cache.read_text())
        except Exception:
            pass
        self._json(colors)

    def _serve_html(self):
        html_file = Path.home() / "Dotfiles/scripts/rgb-dashboard.html"
        if html_file.exists():
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(html_file.read_bytes())
        else:
            self._json({"error": "dashboard not found"}, 404)

    def _serve_case_svg(self):
        """Serve the DS900 Air case SVG with the live OpenRGB color baked in.

        The SVG's RGB elements use CSS var(--rgb); we rewrite that var to the
        current openrgb color so HA picture-elements shows the live color
        without relying on template re-rendering.
        """
        svg_file = Path.home() / "Dotfiles/scripts/freezer-case.svg"
        if not svg_file.exists():
            self._json({"error": "case svg not found"}, 404)
            return
        color = (state.get("openrgb") or {}).get("color", "0b84da") or "0b84da"
        color = color.lstrip("#").lower()
        if len(color) == 3:
            color = "".join(c * 2 for c in color)
        data = svg_file.read_text()
        # Replace the root CSS var (also updates strip/fan fallbacks)
        data = re.sub(r"--rgb:\s*#[0-9a-fA-F]{3,6}", f"--rgb: #{color}", data)
        self.send_response(200)
        self.send_header("Content-Type", "image/svg+xml")
        self.send_header("Cache-Control", "no-cache, max-age=0")
        self.send_header("Content-Length", str(len(data.encode())))
        self.end_headers()
        self.wfile.write(data.encode())


    def do_POST(self):
        body = self._body()
        brightness = body.get("brightness", 80)

        if self.path == "/openrgb":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            if brightness == 0:
                _kill_inflight_fades()
                ok = set_openrgb("000000", 0)
            else:
                ok = set_openrgb(color, brightness)
            self._json({"ok": ok, **state["openrgb"]})

        elif self.path == "/keyboard":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            if brightness == 0:
                _kill_inflight_fades()
                ok = set_keyboard_off() if _cfg("off.keyboard", True) else True
            else:
                ok = set_keyboard(color, brightness)
            self._json({"ok": ok, **state["keyboard"]})

        elif self.path == "/all":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            track_color(color)
            fade = bool(body.get("fade", False))
            # Per-device brightness overrides — default to the master value.
            # Lets the dashboard drive PC/Keyboard/Govee independently.
            kb_bri = body.get("kb_bri", body.get("keyboard_brightness", brightness))
            govee_bri = body.get("govee_bri", body.get("govee_brightness", brightness))
            if color == "000000" or brightness == 0:
                # All Off — instant, every device off (no fade to black).
                # Kill in-flight fades FIRST so a still-running fade can't
                # flash a color after the devices went dark.
                _kill_inflight_fades()
                if state.get("last_color", "000000") != "000000":
                    state["restore_color"] = state["last_color"]
                results: list = [None, None, None]
                def run_openrgb_off():
                    results[0] = set_openrgb("000000", 0)
                def run_keyboard_off():
                    if _cfg("off.keyboard", True):
                        results[1] = set_keyboard_off()
                def run_govee_off():
                    if _cfg("off.govee", True):
                        results[2] = set_govee("000000", 0)
                t1 = threading.Thread(target=run_openrgb_off)
                t2 = threading.Thread(target=run_keyboard_off)
                t3 = threading.Thread(target=run_govee_off)
                t1.start(); t2.start(); t3.start()
                t1.join(timeout=8); t2.join(timeout=8); t3.join(timeout=8)
                self._json({"ok": all(r for r in results if r is not None), "color": "000000", "brightness": 0})
                return
            if fade:
                # Smooth crossfade path — fade-rgb.py (PC + keyboard) and
                # govee-led.py --fade in parallel, same step timing as rgb-sync.sh
                def _govee_fade(c):
                    try:
                        subprocess.run(
                            [sys.executable, str(GOVEE_SCRIPT), c, str(govee_bri), "--fade"],
                            timeout=15, capture_output=True,
                        )
                        state["govee"]["color"] = c
                        state["govee"]["brightness"] = govee_bri
                    except Exception:
                        pass

                t_g = threading.Thread(target=_govee_fade, args=(color,), daemon=True)
                t_g.start()
                try:
                    result = subprocess.run(
                        [sys.executable, str(Path.home() / "Dotfiles/scripts/fade-rgb.py"), color, str(brightness), str(kb_bri)],
                        timeout=10, capture_output=True, text=True,
                    )
                    if result.returncode != 0:
                        print(f"fade-rgb stderr: {result.stderr}", file=sys.stderr)
                except Exception as e:
                    print(f"fade-rgb error: {e}", file=sys.stderr)
                state["openrgb"]["color"] = color
                state["openrgb"]["brightness"] = brightness
                state["openrgb"]["mode"] = "direct"
                state["keyboard"]["color"] = color
                state["keyboard"]["brightness"] = max(kb_bri, 1)
                state["last_color"] = color
                self._json({"ok": True, "color": color, "brightness": brightness, "kb_bri": kb_bri, "govee_bri": govee_bri, "fade": True})
                return
            results: list = [None, None, None]
            def run_openrgb():
                results[0] = set_openrgb(color, brightness)
            def run_keyboard():
                # Keyboard brightness follows its own value (hardware
                # dim byte in mad68-rgb.py). min 1 — 0 means off, handled above.
                results[1] = set_keyboard(color, max(kb_bri, 1))
            def run_govee():
                if govee_bri == 0 and not _cfg("off.govee", True):
                    return  # skip Govee when off is disabled in config
                results[2] = set_govee(color, govee_bri)
            t1 = threading.Thread(target=run_openrgb)
            t2 = threading.Thread(target=run_keyboard)
            t3 = threading.Thread(target=run_govee)
            t1.start(); t2.start(); t3.start()
            t1.join(timeout=8); t2.join(timeout=8); t3.join(timeout=8)
            self._json({"ok": all(r for r in results if r is not None), "color": color, "brightness": brightness, "kb_bri": kb_bri, "govee_bri": govee_bri})

        elif self.path == "/govee":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            if brightness == 0:
                _kill_inflight_fades()
                ok = set_govee("000000", 0) if _cfg("off.govee", True) else True
            else:
                ok = set_govee(color, brightness)
            self._json({"ok": ok, **state.get("govee", {})})

        elif self.path == "/wallpaper":
            ok = trigger_wallpaper(wallpaper_path=current_wallpaper_path())
            self._json({"ok": ok})

        elif self.path == "/wallpaper/set":
            name = body.get("name", body.get("wallpaper", ""))
            if not name:
                self._json({"error": "wallpaper name required"}, 400)
                return
            ok = set_wallpaper(name)
            if ok:
                self._json({"ok": True, "wallpaper": name})
            else:
                self._json({"error": "wallpaper not found", "name": name}, 404)

        elif self.path == "/wallpapers":
            names = list_wallpapers()
            self._json({
                "wallpapers": names,
                "wallpapers_detailed": [
                    {"name": n, "thumbnail": f"http://localhost:5070/wallpaper/image/{n}"}
                    for n in names
                ]
            })

        elif self.path == "/brightness":
            b = brightness
            # After All Off, last_color is black — restore to the remembered
            # color so raising brightness actually lights the devices again.
            current_color = state.get("last_color", "000000")
            if current_color == "000000":
                current_color = state.get("restore_color", "00dbeb")
            if b == 0:
                _kill_inflight_fades()
            results: list = [None, None, None]
            def run_openrgb_b():
                results[0] = set_openrgb(current_color, b)
            def run_keyboard_b():
                if b > 0:
                    results[1] = set_keyboard(current_color, max(b, 1))
                elif _cfg("off.keyboard", True):
                    results[1] = set_keyboard_off()
            def run_govee_b():
                if b > 0:
                    results[2] = set_govee(current_color, b)
                elif _cfg("off.govee", True):
                    results[2] = set_govee("000000", 0)
            t1 = threading.Thread(target=run_openrgb_b)
            t2 = threading.Thread(target=run_keyboard_b)
            t3 = threading.Thread(target=run_govee_b)
            t1.start(); t2.start(); t3.start()
            t1.join(timeout=8); t2.join(timeout=8); t3.join(timeout=8)
            self._json({"ok": all(r for r in results if r is not None), "brightness": b})

        elif self.path == "/sync":
            result = trigger_sync()
            self._json(result)

        elif self.path == "/power":
            action = body.get("action", "").strip().lower()
            cmd = {
                "suspend": ["systemctl", "suspend", "--no-block"],
                "sleep": ["systemctl", "suspend", "--no-block"],
                "reboot": ["systemctl", "reboot", "--no-block"],
                "restart": ["systemctl", "reboot", "--no-block"],
                "shutdown": ["systemctl", "poweroff", "--no-block"],
                "poweroff": ["systemctl", "poweroff", "--no-block"],
            }.get(action)
            if not cmd:
                self._json({"error": "action must be one of suspend|reboot|shutdown", "action": action}, 400)
                return
            # Dry-run: validate without executing (safe for testing)
            if body.get("dry_run") or body.get("dry-run") or body.get("test"):
                self._json({"ok": True, "dry_run": True, "action": action, "cmd": " ".join(cmd)})
                return
            try:
                subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                self._json({"ok": True, "action": action})
            except Exception as e:
                self._json({"error": str(e), "action": action}, 500)

        else:
            self._json({"error": "not found"}, 404)


# ── Main ────────────────────────────────────────────────────────────────

# Startup flash fix: when OpenRGB restarts (e.g. at boot), it defaults to
# some default lighting mode. We immediately set it to the last known color
# so there's no rainbow flash before the first sync runs.
_STARTUP_FLASH_FIXED = False


def _apply_state_to_devices(reason: str = "startup"):
    """Re-apply the last known color/brightness to all devices.

    Used at startup (prevent rainbow flash before first sync) and on
    resume from suspend (hardware reinitializes to default lighting).
    Persisted restore_brightness keeps per-device brightness instead of
    resetting everything to the 80% default.
    Returns True when all enabled devices were applied.
    """
    color = state.get("last_color") or state.get("restore_color", "00dbeb")
    bri = state.get("restore_brightness", {}).get("openrgb", 80)
    kb_bri = state.get("restore_brightness", {}).get("keyboard", 80)
    govee_bri = state.get("restore_brightness", {}).get("govee", 80)
    results = []
    if color != "000000":
        results.append(("openrgb", set_openrgb(color, bri)))
    if kb_bri > 0:
        results.append(("keyboard", set_keyboard(color, max(kb_bri, 1))))
    if govee_bri > 0:
        results.append(("govee", set_govee(color, govee_bri)))
    failed = [name for name, r in results if not r]
    if failed:
        print(f"State applied ({reason}): #{color} — FAILED: {', '.join(failed)}", file=sys.stderr)
    else:
        print(f"State applied ({reason}): #{color} bri={bri}/{kb_bri}/{govee_bri}", file=sys.stderr)
    return not failed


def _openrgb_device_count(host: str, port: int) -> int:
    """Ask the OpenRGB server how many devices are enumerated.

    Sends the REQUEST_CONTROLLER_COUNT packet (type 0, empty payload); the
    server replies with a 16-byte header whose packet_size=4, then a 4-byte
    count payload. Returns -1 when the server isn't reachable or
    protocol-ready yet. Cheaper than a full OpenRGBClient connect — no
    device data transfer.
    """
    import socket, struct
    try:
        s = socket.create_connection((host, port), timeout=2)
        try:
            header = struct.pack("ccccIII", b"O", b"R", b"G", b"B", 0, 0, 0)
            s.sendall(header)
            s.settimeout(2)
            # Reply = 16-byte header (packet_size=4) + 4-byte count payload.
            # TCP can split them; read until we have all 20 bytes.
            resp = b""
            while len(resp) < 20:
                chunk = s.recv(20 - len(resp))
                if not chunk:
                    break
                resp += chunk
            if len(resp) >= 20:
                # 16-byte reply header, then the 4-byte count payload
                return struct.unpack("I", resp[16:20])[0]
            return -1
        finally:
            s.close()
    except OSError:
        return -1


def _apply_with_stabilization(reason: str, deadline_seconds: int = 90) -> bool:
    """Apply state, re-applying until the OpenRGB device list stabilizes.

    OpenRGB enumerates devices asynchronously after the listen socket opens
    (on this machine the ASUS board registers ~16s after the server starts,
    long after the DRAM sticks). A single apply misses late devices, so poll
    the device count and re-apply whenever it changes, exiting after 2 stable
    polls with a non-empty device list. Bounded by the deadline so a genuinely
    down server doesn't spin forever. Returns True once stabilized.
    """
    import socket, struct
    host = _cfg("openrgb.host", "localhost")
    port = _safe_int(_cfg("openrgb.port", 6742), 6742)
    deadline = time.time() + deadline_seconds
    prev_count = -1
    stable_polls = 0
    while time.time() < deadline:
        count = _openrgb_device_count(host, port)
        try:
            if count >= 0:
                if count != prev_count:
                    # New device appeared (or first sighting) — apply to it too
                    if _apply_state_to_devices(reason):
                        stable_polls = 0
                    prev_count = count
                else:
                    stable_polls += 1
                    if stable_polls >= 2 and count > 0:
                        # Device list stable and non-empty — done
                        return True
        except Exception as e:
            print(f"State apply ({reason}) error: {e}", file=sys.stderr)
        time.sleep(5)
    print(f"State apply ({reason}): giving up after {deadline_seconds}s", file=sys.stderr)
    return False


def _apply_startup_state():
    """Apply the last known RGB state to prevent flash on first boot.

    The OpenRGB server is often still enumerating devices when the bridge
    starts, and it can crash+restart during early boot (SEGV on premature
    connections). Retry until every device applies cleanly, so a
    slow/crashing server still gets the persisted color once it is stable.
    """
    global _STARTUP_FLASH_FIXED
    if _STARTUP_FLASH_FIXED:
        return
    if _apply_with_stabilization("startup", 90):
        _STARTUP_FLASH_FIXED = True


def _openrgb_server_watcher():
    """Detect OpenRGB server down→up transitions and re-apply state.

    The server can crash and be restarted by systemd (SEGV on premature
    connections, `Restart=always`). Every restart resets hardware to
    default lighting, so when the server comes back we must re-push the
    persisted color. Poll the protocol readiness probe; when the server
    goes from down to up, run the stabilization apply in a background
    thread so the watcher keeps polling for further transitions.
    """
    import socket, struct, time
    host = _cfg("openrgb.host", "localhost")
    port = _safe_int(_cfg("openrgb.port", 6742), 6742)

    def _probe():
        try:
            s = socket.create_connection((host, port), timeout=1)
            try:
                header = struct.pack("ccccIII", b"O", b"R", b"G", b"B", 0, 40, 4)
                s.sendall(header)
                s.sendall(struct.pack("I", 4))
                s.settimeout(1)
                return len(s.recv(16)) >= 16
            finally:
                s.close()
        except OSError:
            return False

    # Skip until the first successful probe, then arm the watcher.
    while not _probe():
        time.sleep(2)
    was_up = True
    while True:
        time.sleep(3)
        up = _probe()
        if up and not was_up:
            print("OpenRGB server recovered — re-applying state", file=sys.stderr)
            threading.Thread(
                target=_apply_with_stabilization,
                args=("server-recovered", 60),
                daemon=True,
            ).start()
        was_up = up


def _wake_listener():
    """Re-apply RGB state after resume from suspend.

    MAD68 + OpenRGB + Govee reinitialize to hardware-default lighting on
    wake (MAD68 goes white, OpenRGB goes rainbow). Listen for logind's
    PrepareForSleep signal: when sleeping=False (just woke), re-apply the
    persisted color/brightness. Runs in its own thread with a GLib loop
    because dbus-python isn't asyncio-native.
    """
    try:
        import dbus
        from dbus.mainloop.glib import DBusGMainLoop
        from gi.repository import GLib  # type: ignore[reportAttributeAccessIssue]  # PyGObject loads at runtime

        DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
        loop = GLib.MainLoop()

        def _on_prepare_sleep(sleeping: bool):
            if sleeping:
                print("PrepareForSleep: sleeping", file=sys.stderr)
            else:
                print("PrepareForSleep: waking — re-applying RGB", file=sys.stderr)
                try:
                    _apply_state_to_devices("wake")
                except Exception as e:
                    print(f"Wake state apply failed: {e}", file=sys.stderr)

        bus.add_signal_receiver(
            _on_prepare_sleep,
            signal_name="PrepareForSleep",
            dbus_interface="org.freedesktop.login1.Manager",
            path="/org/freedesktop/login1",
            arg0=None,
        )
        loop.run()
    except ImportError:
        print("dbus not available — wake re-apply disabled", file=sys.stderr)
    except Exception as e:
        print(f"Wake listener error: {e}", file=sys.stderr)


def _ws_server():
    """Run the WebSocket server for real-time state updates."""
    try:
        import asyncio
        from websockets.asyncio.server import serve

        async def handler(ws):
            _ws_clients.append(ws)
            try:
                # Send initial state
                payload = json.dumps({"type": "update", "state": state, "metrics": get_system_metrics()})
                await ws.send(payload)
                # Keep connection alive
                async for msg in ws:
                    pass
            except Exception:
                pass
            finally:
                if ws in _ws_clients:
                    _ws_clients.remove(ws)

        async def run():
            import asyncio
            # Periodic broadcast every 5 seconds
            async def broadcaster():
                while True:
                    _broadcast_state_async()
                    await asyncio.sleep(5)

            async with serve(handler, "0.0.0.0", WS_PORT) as server:
                print(f"WebSocket server on ws://0.0.0.0:{WS_PORT}", file=sys.stderr)
                await asyncio.gather(
                    broadcaster(),
                    server.serve_forever(),
                )

        asyncio.run(run())
    except ImportError:
        print("websockets library not installed — WS endpoint disabled", file=sys.stderr)
    except Exception as e:
        print(f"WebSocket server error: {e}", file=sys.stderr)


def _broadcast_state_async():
    """Async version of _broadcast_state for the WS broadcaster."""
    import asyncio
    payload = json.dumps({"type": "update", "state": state, "metrics": get_system_metrics()})
    for ws in list(_ws_clients):
        try:
            asyncio.create_task(ws.send(payload))
        except Exception:
            if ws in _ws_clients:
                _ws_clients.remove(ws)


def _start_ws_thread():
    """Start the WebSocket server in a background thread."""
    t = threading.Thread(target=_ws_server, daemon=True)
    t.start()


if __name__ == "__main__":
    # Apply startup state to prevent flash before first sync
    threading.Thread(target=_apply_startup_state, daemon=True).start()

    # Re-apply RGB after resume from suspend (hardware resets to defaults)
    threading.Thread(target=_wake_listener, daemon=True).start()

    # Watch for OpenRGB server crash/restart and re-apply state when it
    # comes back (systemd Restart=always resets hardware to default)
    threading.Thread(target=_openrgb_server_watcher, daemon=True).start()

    # Start WebSocket server for real-time updates
    _start_ws_thread()

    server = ThreadingHTTPServer(("0.0.0.0", PORT), RGBHandler)
    print(f"RGB Bridge listening on http://0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down")
        server.shutdown()
