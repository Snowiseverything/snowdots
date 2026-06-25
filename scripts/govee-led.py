#!/usr/bin/env python3
"""Control Govee LED strip via Home Assistant API (or BLE fallback).

Usage:
  govee-led.py <hex_color>               # set color (e.g. ff00ff)
  govee-led.py <r> <g> <b>              # set color (0-255 each)
  govee-led.py --brightness <0-100>      # set brightness
  govee-led.py on | off                  # power on/off
  govee-led.py discover                  # scan for Govee BLE devices

Config (first match wins):
  1. Command-line args
  2. Environment variables: HA_URL, HA_TOKEN, GOVEE_ENTITY
  3. Config file: ~/.config/govee-led.toml
"""
import asyncio, os, sys, tomllib
from pathlib import Path

# ── defaults ────────────────────────────────────────────────────────────
CONFIG_FILE = Path.home() / ".config" / "govee-led.toml"
HA_DEFAULT_URL = "http://100.83.33.67:8123"

def load_config():
    cfg = {}
    if CONFIG_FILE.exists():
        with open(CONFIG_FILE, "rb") as f:
            cfg = tomllib.load(f)
    env = {
        "ha_url": os.environ.get("HA_URL"),
        "ha_token": os.environ.get("HA_TOKEN"),
        "entity": os.environ.get("GOVEE_ENTITY"),
    }
    env = {k: v for k, v in env.items() if v}
    cfg.update(env)
    return cfg

async def ha_api(method, endpoint, data=None):
    cfg = load_config()
    url = cfg.get("ha_url", HA_DEFAULT_URL)
    token = cfg.get("ha_token")
    if not token:
        print("HA_TOKEN not set. Set HA_URL and HA_TOKEN env vars or ~/.config/govee-led.toml", file=sys.stderr)
        return None
    import httpx
    async with httpx.AsyncClient(verify=False) as client:
        headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
        r = await client.request(method, f"{url}/api/{endpoint}", headers=headers, json=data, timeout=5)
        r.raise_for_status()
        return r.json()

async def ha_call_service(service, data):
    entity = load_config().get("entity", "light.govee_h6102_2f48")
    return await ha_api("POST", f"services/{service}", {**data, "entity_id": entity})

async def main():
    args = sys.argv[1:]
    cfg = load_config()

    if not args:
        print(__doc__.strip())
        return

    # discover via BLE (no HA needed)
    if args[0] == "discover":
        from bleak import BleakScanner
        devs = await BleakScanner.discover(timeout=5)
        for d in devs:
            if d.name and "Govee" in d.name:
                print(f"  {d.address}  {d.name}")
        return

    token = cfg.get("ha_token")
    if token:
        try:
            if args[0] == "on":
                r = await ha_call_service("light/turn_on", {})
                print("Power on" if r else "Failed")
            elif args[0] == "off":
                r = await ha_call_service("light/turn_off", {})
                print("Power off" if r else "Failed")
            elif args[0] == "--brightness":
                b = int(args[1]) if len(args) > 1 else 50
                r = await ha_call_service("light/turn_on", {"brightness_pct": b})
                print(f"Brightness {b}%" if r else "Failed")
            else:
                hex_color = args[0].lstrip("#")
                rv, gv, bv = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
                brightness = int(args[1]) if len(args) > 1 else 100
                # Retry up to 3 times — Govee BLE may need wake-up on first call
                for attempt in range(3):
                    try:
                        result = await ha_call_service("light/turn_on", {
                            "rgb_color": [rv, gv, bv], "brightness_pct": brightness
                        })
                        if result is not None:
                            print(f"Set #{rv:02x}{gv:02x}{bv:02x} at {brightness}%")
                            return
                    except Exception as e:
                        if attempt < 2:
                            await asyncio.sleep(0.5)
                        else:
                            raise
                print("Failed")
            return
        except Exception as e:
            print(f"HA API failed ({e}), falling back to BLE...", file=sys.stderr)

    # ── BLE fallback ────────────────────────────────────────────────────
    from bleak_retry_connector import BleakClientWithServiceCache, establish_connection
    from bleak import BleakScanner

    DEVICE_ADDR = "C6:32:38:31:2F:48"
    DEVICE_NAME = "Govee_H6102_2F48"
    WRITE_CHAR = "00010203-0405-0607-0809-0a0b0c0d1911"

    def make_cmd(data: bytes) -> bytes:
        return data.ljust(20, b'\x00')

    async def send_cmd(cmd: bytes):
        device = await BleakScanner.find_device_by_address(DEVICE_ADDR, timeout=10)
        if not device:
            print("Device not found", file=sys.stderr)
            return
        client = await establish_connection(
            BleakClientWithServiceCache, device, DEVICE_NAME,
            disconnected_callback=lambda c: None,
        )
        try:
            await client.write_gatt_char(WRITE_CHAR, cmd, response=False)
        finally:
            await client.disconnect()

    if args[0] in ("on", "off"):
        cmd = make_cmd(bytes([0x33, 0x01, 0x01 if args[0] == "on" else 0x00]))
        await send_cmd(cmd)
        print(f"Power {args[0]} (BLE)")
        return

    if args[0] == "--brightness":
        b = max(0, min(100, int(args[1]) if len(args) > 1 else 50))
        level = int(b * 255 / 100)
        cmd = make_cmd(bytes([0x33, 0x04, level]))
        await send_cmd(cmd)
        print(f"Brightness {b}% (BLE)")
        return

    r = g = b = 0
    brightness = 100
    hex_color = args[0].lstrip("#")
    if len(hex_color) >= 6:
        r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    if len(args) > 1:
        brightness = int(args[1])

    cmd = make_cmd(bytes([0x33, 0x01, 0x01]))
    await send_cmd(cmd)
    await asyncio.sleep(0.15)
    level = int(max(0, min(100, brightness)) * 255 / 100)
    cmd = make_cmd(bytes([0x33, 0x05, r, g, b, level]))
    await send_cmd(cmd)
    print(f"Set #{r:02x}{g:02x}{b:02x} at {brightness}% (BLE)")

asyncio.run(main())
