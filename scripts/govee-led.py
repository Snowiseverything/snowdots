#!/usr/bin/env python3
"""Control Govee LED strip via direct BLE (Freezer) with HA fallback.

Usage:
  govee-led.py <hex_color>               # set color (e.g. ff00ff)
  govee-led.py <hex_color> <brightness>  # set color + brightness (0-100)
  govee-led.py --brightness <0-100>      # set brightness
  govee-led.py on | off                  # power on/off
  govee-led.py discover                  # scan for Govee BLE devices
"""
import sys, asyncio, json, os, urllib.request
from pathlib import Path

# ── Config ────────────────────────────────────────────────────────────────
sys.path.insert(0, str(Path.home() / ".local/bin"))
try:
    from rgb_config import load_config, config_value
    _CFG = load_config()
except Exception:
    _CFG = None


def _cfg(key, default):
    if _CFG is None:
        return default
    keys = key.split(".")
    return config_value(_CFG, *keys, default=default)


CONFIG = Path.home() / ".config/govee-led.toml"
HA_URL = _cfg("govee.api_url", "http://192.168.1.35:8125")
HA_TOKEN = ""
ENTITY = "light.govee_h6102_2f48"

if CONFIG.exists():
    for line in CONFIG.read_text().splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip().strip('"')
            if k == "ha_token":
                HA_TOKEN = v
            elif k == "entity":
                ENTITY = v
            elif k == "ha_url":
                HA_URL = v

GOVEE_ADDR = "C6:32:38:31:2F:48"
WRITE_CHAR = "00010203-0405-0607-0809-0a0b0c0d2b11"
FAST_SOCK = "/tmp/govee-fast.sock"

LAST_COLOR = Path("/tmp/govee-last-color")
FADE_STEPS = 5
FADE_DELAY_MS = 20


def _fast_send(cmd: str) -> bool:
    """Send to the fast-daemon socket. Returns True on 'ok' response."""
    import socket
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.settimeout(2)
        s.connect(FAST_SOCK)
        s.sendall((cmd + "\n").encode())
        resp = s.recv(1024).decode().strip()
        s.close()
        return resp == "ok"
    except Exception:
        return False



def ha_call(endpoint, data=None):
    req = urllib.request.Request(
        f"{HA_URL}/api/{endpoint}",
        data=json.dumps(data).encode() if data else None,
        headers={
            "Authorization": f"Bearer {HA_TOKEN}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=5) as resp:
        return json.loads(resp.read())


def make_cmd(data):
    buf = bytearray(data + [0x00] * (19 - len(data)))
    chk = 0
    for b in buf:
        chk ^= b
    buf.append(chk)
    return buf


def _color_pkt(r, g, b):
    return make_cmd([0x33, 0x05, 0x15, 0x01, r, g, b, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x7F])


def read_last_color():
    if LAST_COLOR.exists():
        parts = LAST_COLOR.read_text().strip().split()
        if len(parts) == 3:
            return int(parts[0]), int(parts[1]), int(parts[2])
    return None


def write_last_color(r, g, b):
    LAST_COLOR.write_text(f"{r} {g} {b}\n")


async def _ble_write(cmd):
    from bleak import BleakClient

    try:
        async with BleakClient(GOVEE_ADDR, timeout=10) as client:
            await client.write_gatt_char(WRITE_CHAR, cmd, response=False)
            return "ble"
    except Exception:
        return None


async def ble_fade_color(fr, fg, fb, r, g, b):
    from bleak import BleakClient

    try:
        async with BleakClient(GOVEE_ADDR, timeout=10) as client:
            for i in range(1, FADE_STEPS + 1):
                t = i / FADE_STEPS
                ri = int(fr + (r - fr) * t)
                gi = int(fg + (g - fg) * t)
                bi = int(fb + (b - fb) * t)
                await client.write_gatt_char(WRITE_CHAR, _color_pkt(ri, gi, bi), response=False)
                await asyncio.sleep(FADE_DELAY_MS / 1000)
        return "ble"
    except Exception:
        return None


async def ble_set_color(r, g, b, brightness=100):
    last = read_last_color()
    if last:
        result = await ble_fade_color(*last, r, g, b)
    else:
        result = await _ble_write(_color_pkt(r, g, b))
    if result:
        write_last_color(r, g, b)
        if brightness != 100:
            await asyncio.sleep(0.05)
            await ble_brightness(brightness)
    return result


async def ble_on():
    return await _ble_write(make_cmd([0x33, 0x01, 0x01]))


async def ble_off():
    return await _ble_write(make_cmd([0x33, 0x01, 0x00]))


async def ble_brightness(pct):
    level = max(1, min(100, pct))
    return await _ble_write(make_cmd([0x33, 0x04, level]))


def ha_fade_color(r, g, b, steps=None, brightness=80):
    """Set Govee color instantly via HA — no fade steps needed."""
    pct = max(1, min(100, brightness))
    ha_call("services/light/turn_on", {
        "entity_id": ENTITY,
        "rgb_color": [r, g, b],
        "brightness_pct": pct,
    })


def set_via_ha(endpoint, data, msg):
    ha_call(endpoint, data)
    print(f"{msg} via HA")


def main():
    args = sys.argv[1:]
    if not args:
        print((__doc__ or "").strip())
        return

    fade_mode = "--fade" in args
    if fade_mode:
        args.remove("--fade")

    if args[0] == "discover":
        try:
            from bleak import BleakScanner

            async def scan():
                devices = await BleakScanner.discover(timeout=5)
                for d in devices:
                    if d.name and "Govee" in d.name:
                        print(f"{d.address} {d.name}")
                print("---")
            asyncio.run(scan())
        except Exception:
            pass
        r = ha_call("states")
        for s in r:
            if "govee" in s.get("entity_id", "").lower():
                eid = s["entity_id"]
                state = s.get("state", "?")
                color = s.get("attributes", {}).get("rgb_color", "?")
                print(f"{eid}: {state} rgb={color}")
        return

    if args[0] == "on":
        try:
            ha_call(f"services/light/turn_on", {"entity_id": ENTITY})
            print("Power on via HA")
            return
        except Exception:
            pass
        result = asyncio.run(ble_on())
        if result == "ble":
            print("Power on via BLE")
            return
        return

    if args[0] == "off":
        try:
            ha_call(f"services/light/turn_off", {"entity_id": ENTITY})
            print("Power off via HA")
            return
        except Exception:
            pass
        result = asyncio.run(ble_off())
        if result == "ble":
            print("Power off via BLE")
            return
        return

    if args[0] == "--brightness":
        b = int(args[1]) if len(args) > 1 else 50
        pct = max(1, min(100, b))
        try:
            ha_call(f"services/light/turn_on", {"entity_id": ENTITY, "brightness_pct": pct})
            print(f"Brightness {pct}% via HA")
            return
        except Exception:
            pass
        result = asyncio.run(ble_brightness(b))
        if result == "ble":
            print(f"Brightness {b}% via BLE")
            return
        return

    r = g = b = 0
    brightness = 100
    hex_color = args[0].lstrip("#")
    if len(hex_color) >= 6:
        r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    if len(args) > 1:
        brightness = int(args[1])

    # Apply brightness dimming to the actual target color
    factor = max(0, min(100, brightness)) / 100.0
    dr, dg, db = int(r * factor), int(g * factor), int(b * factor)
    dimmed_hex = f"{dr:02x}{dg:02x}{db:02x}"

    color_hex = f"{r:02x}{g:02x}{b:02x}"

    # Skip if already at target (compare dimmed values — govee-last stores dimmed)
    last = read_last_color()
    if last and last == (dr, dg, db):
        print(f"Already #{color_hex} at {brightness}%")
        return

    # Save dimmed target as last_color for BLE fade interpolation
    orig_last = last
    write_last_color(dr, dg, db)

    # ── Fast socket daemon first (persistent BLE, ~5ms) ─────────────────
    # Send DIMMED color hex — daemon ignores brightness param
    if _fast_send(f"fade {dimmed_hex} {brightness}"):
        print(f"Set #{color_hex} at {brightness}% via socket")
        return

    # ── HA first — fast local network call to Snowpi ─────────────────────
    # Check if Govee is actually available before trusting HA
    try:
        ha_state = ha_call(f"states/{ENTITY}")
        if ha_state.get("state") != "unavailable":
            ha_fade_color(dr, dg, db, brightness=brightness)
            print(f"Set #{color_hex} at {brightness}% via HA")
            return
    except Exception:
        pass

    # ── HA unavailable or failed — fall back to direct BLE ───────────────
    if fade_mode and orig_last:
        result = asyncio.run(ble_fade_color(*orig_last, dr, dg, db))
        if result == "ble":
            print(f"Set #{color_hex} at {brightness}% via BLE fade")
            return
    else:
        result = asyncio.run(ble_set_color(dr, dg, db, brightness))
        if result == "ble":
            print(f"Set #{color_hex} at {brightness}% via BLE")
            return

    # All paths exhausted — clear last_color so next call retries
    # (device wasn't actually changed, skipping would be incorrect)
    try:
        LAST_COLOR.unlink()
    except OSError:
        pass
    print(f"Set #{color_hex} FAILED (HA + BLE both unreachable)")


if __name__ == "__main__":
    main()
