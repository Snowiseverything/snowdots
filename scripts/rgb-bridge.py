#!/usr/bin/env python3
"""RGB Bridge — REST API for OpenRGB + MAD68 keyboard.

Controls OpenRGB and MAD68 keyboard over HTTP so Home Assistant
and other clients can set colors without direct hardware access.

Port: 5070

Endpoints:
  GET  /status                    — current state of all devices
  POST /openrgb                   — set OpenRGB color
  POST /keyboard                  — set MAD68 keyboard color
  POST /all                       — set all devices at once
  POST /sync                      — trigger rgb-sync.sh (wallpaper colors)
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

PORT = 5070
MAD68_SCRIPT = Path.home() / ".local/bin/mad68-rgb.py"
SYNC_SCRIPT = Path.home() / "Dotfiles/scripts/rgb-sync.sh"
GOVEE_SCRIPT = Path.home() / "Dotfiles/scripts/govee-led.py"

# ── State tracking ──────────────────────────────────────────────────────
state = {
    "openrgb": {"color": "000000", "brightness": 50, "mode": "static"},
    "keyboard": {"color": "000000"},
    "govee": {"color": "000000", "brightness": 80},
    "synced": False,
    "last_sync": None,
}


def set_openrgb(color: str, brightness: int = 50):
    """Set OpenRGB color via CLI."""
    try:
        subprocess.run(
            ["openrgb", "--mode", "static", "--color", color, "--brightness", str(brightness)],
            timeout=5, capture_output=True,
        )
        state["openrgb"] = {"color": color, "brightness": brightness, "mode": "static"}
        return True
    except Exception as e:
        print(f"OpenRGB error: {e}", file=sys.stderr)
        return False


def set_keyboard(color: str, brightness: int = 70):
    """Set MAD68 keyboard color via HID."""
    try:
        subprocess.run(
            [sys.executable, str(MAD68_SCRIPT), color, str(brightness)],
            timeout=5, capture_output=True,
        )
        state["keyboard"] = {"color": color}
        return True
    except Exception as e:
        print(f"Keyboard error: {e}", file=sys.stderr)
        return False


def set_govee(color: str, brightness: int = 80):
    """Set Govee LED strip via HA API."""
    try:
        subprocess.run(
            [sys.executable, str(GOVEE_SCRIPT), color, str(brightness)],
            timeout=10, capture_output=True,
        )
        state["govee"] = {"color": color, "brightness": brightness}
        return True
    except Exception as e:
        print(f"Govee error: {e}", file=sys.stderr)
        return False


def trigger_sync():
    """Run rgb-sync.sh to apply wallpaper-matched colors."""
    try:
        subprocess.run(
            ["bash", str(SYNC_SCRIPT)],
            timeout=30, capture_output=True,
        )
        # Read the accent from colors.json and calculate unified LED color
        import colorsys, json as _json
        colors_file = Path.home() / ".cache/skwd-wall/colors.json"
        if colors_file.exists():
            data = _json.loads(colors_file.read_text())
            accent = data.get("accent", "#000000").lstrip("#")
            r, g, b = int(accent[0:2], 16) / 255.0, int(accent[2:4], 16) / 255.0, int(accent[4:6], 16) / 255.0
            h, l, s = colorsys.rgb_to_hls(r, g, b)
            rl, gl, bl = colorsys.hls_to_rgb(h, 0.45, 0.90)
            color = '%02x%02x%02x' % (int(rl * 255), int(gl * 255), int(bl * 255))
            state["openrgb"]["color"] = color
            state["keyboard"]["color"] = color
            state["govee"]["color"] = color
        state["synced"] = True
        return True
    except Exception as e:
        print(f"Sync error: {e}", file=sys.stderr)
        return False


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
    def log_message(self, fmt, *args):
        pass  # suppress default logging

    def _json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def _body(self) -> dict:
        length = int(self.headers.get("Content-Length", 0))
        if length == 0:
            return {}
        return json.loads(self.rfile.read(length))

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        if self.path in ("/status", "/current"):
            self._json(state)
        elif self.path == "/ping":
            self._json({"status": "ok"})
        elif self.path == "/recent":
            self._json_recent()
        elif self.path == "/" or self.path == "/dashboard":
            self._serve_html()
        else:
            self._json({"error": "not found"}, 404)

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
        brightness = body.get("brightness", 50)

        if self.path == "/openrgb":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            ok = set_openrgb(color, brightness)
            self._json({"ok": ok, **state["openrgb"]})

        elif self.path == "/keyboard":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            ok = set_keyboard(color)
            self._json({"ok": ok, **state["keyboard"]})

        elif self.path == "/all":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            track_color(color)
            results = [None, None, None]
            def run_openrgb():
                results[0] = set_openrgb(color, brightness)
            def run_keyboard():
                results[1] = set_keyboard(color, brightness)
            def run_govee():
                results[2] = set_govee(color, brightness)
            t1 = threading.Thread(target=run_openrgb)
            t2 = threading.Thread(target=run_keyboard)
            t3 = threading.Thread(target=run_govee)
            t1.start(); t2.start(); t3.start()
            t1.join(timeout=8); t2.join(timeout=8); t3.join(timeout=8)
            self._json({"ok": all(r for r in results if r is not None), "color": color, "brightness": brightness})

        elif self.path == "/govee":
            color = parse_color(body)
            if not color:
                self._json({"error": "color required"}, 400)
                return
            ok = set_govee(color, brightness)
            self._json({"ok": ok, **state.get("govee", {})})

        elif self.path == "/sync":
            ok = trigger_sync()
            self._json({"ok": ok})

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
