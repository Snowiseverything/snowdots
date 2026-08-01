#!/usr/bin/env python3
"""RGB Bridge — REST API for OpenRGB + MAD68 keyboard.

Controls OpenRGB and MAD68 keyboard over HTTP so Home Assistant
and other clients can set colors without direct hardware access.

Port: 5070

Endpoints:
  GET  /status                    — current state of all devices
  GET  /wallpapers                — list available wallpaper files
  POST /openrgb                   — set OpenRGB color
  POST /keyboard                  — set MAD68 keyboard color
  POST /all                       — set all devices at once
  POST /sync                      — trigger rgb-sync.sh (wallpaper colors)
  POST /wallpaper                 — trigger wall-sync.sh (re-apply current wallpaper + colors)
  POST /wallpaper/set             — set wallpaper by filename (e.g. {"name": "wallpaper.jpg"})
  GET  /ping                      — health check

Body format (JSON):
  {"color": "ff0000"}             — hex color, no #
  {"color": "ff0000", "brightness": 50}  — 0-100

Example:
  curl -X POST http://localhost:5070/all -d '{"color":"ff0000","brightness":50}'
"""

import json, os, subprocess, sys, threading
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

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
MAD68_SCRIPT = Path.home() / ".local/bin/mad68-rgb.py"
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
    "synced": False,
    "last_sync": None,
    "wallpaper": current_wallpaper_name(),
}


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
    try:
        from openrgb import OpenRGBClient
        from openrgb.utils import RGBColor
        orgb = OpenRGBClient(_cfg("openrgb.host", "localhost"), _safe_int(_cfg("openrgb.port", 6742), 6742), name="rgb-bridge")
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
    # Sync ONLY refreshes color — it preserves each device's own brightness.
    # A device that's off (bri 0) stays off; it just picks up the new color
    # for when it's turned back on. No forced restore to 80.

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
        # If every device is off, sync = silent color refresh only.
        # Running fade-rgb at brightness 0 would flash PC to black; skip it.
        all_off = (bri == 0 and kb_bri == 0 and govee_bri == 0)
        if all_off:
            state["openrgb"]["color"] = color
            state["openrgb"]["brightness"] = 0
            state["openrgb"]["mode"] = "direct"
            state["keyboard"]["color"] = color
            state["keyboard"]["brightness"] = 0
            state["govee"]["color"] = color
            state["govee"]["brightness"] = 0
            state["last_color"] = color
            state["restore_color"] = color
            return {"ok": True, "message": message}

        t_govee = threading.Thread(target=_govee_async, args=(color,), daemon=True)
        t_govee.start()
        # PC devices via fade-rgb.py (crossfade, ~0.6s) — pass keyboard's
        # own brightness so it doesn't get reset to the PC value.
        # pc_brightness=0 (off) → fade-rgb skips PC color writes (no flash).
        result = subprocess.run(
            [sys.executable, str(Path.home() / "Dotfiles/scripts/fade-rgb.py"), color, str(bri), str(kb_bri)],
            timeout=10, capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"fade-rgb stderr: {result.stderr}", file=sys.stderr)
        state["openrgb"]["color"] = color
        state["openrgb"]["brightness"] = bri
        state["openrgb"]["mode"] = "direct"
        state["keyboard"]["color"] = color
        state["keyboard"]["brightness"] = max(kb_bri, 1) if kb_bri > 0 else 0
        state["last_color"] = color
        state["restore_color"] = color
        state["last_color"] = color
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
        if self.path in ("/status", "/current"):
            self._json(state)
        elif self.path == "/ping":
            self._json({"status": "ok"})
        elif self.path == "/wallpapers":
            names = list_wallpapers()
            self._json({
                "wallpapers": names,
                "wallpapers_detailed": [
                    {"name": n, "thumbnail": f"http://localhost:5070/wallpaper/image/{n}"}
                    for n in names
                ]
            })
        elif self.path.startswith("/wallpaper/image/"):
            name = self.path.split("/wallpaper/image/")[-1]
            self._serve_wallpaper_image(name)
        elif self.path == "/recent":
            self._json_recent()
        elif self.path == "/" or self.path == "/dashboard":
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

        else:
            self._json({"error": "not found"}, 404)


# ── Main ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    server = HTTPServer(("0.0.0.0", PORT), RGBHandler)
    print(f"RGB Bridge listening on http://0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down")
        server.shutdown()
