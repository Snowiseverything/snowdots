#!/usr/bin/env python3
"""Control Govee LED strip via BLE on Snowpi (closer to the light).

Usage:
  govee-led.py <hex_color>               # set color (e.g. ff00ff)
  govee-led.py --brightness <0-100>      # set brightness
  govee-led.py on | off                  # power on/off
  govee-led.py discover                  # scan for Govee BLE devices
"""
import sys, subprocess

SNOWPI = "snow@100.83.33.67"
ADDR = "C6:32:38:31:2F:48"

def make_cmd(data):
    return data.hex()

def ssh_ble(*cmds):
    result = subprocess.run(
        ["ssh", SNOWPI, "python3", "/tmp/govee-helper.py", *cmds],
        capture_output=True, text=True, timeout=35
    )
    if result.returncode != 0:
        print(f"BLE error: {(result.stderr or result.stdout).strip()}", file=sys.stderr)
        return False
    return True

def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__.strip())
        return

    if args[0] == "discover":
        r = subprocess.run(["ssh", SNOWPI, "python3", "-c", """
import asyncio
from bleak import BleakScanner
async def s():
    for d in await BleakScanner.discover(timeout=5):
        if d.name and "Govee" in d.name:
            print(d.address, d.name)
asyncio.run(s())
"""], capture_output=True, text=True, timeout=15)
        print(r.stdout.strip() or r.stderr.strip())
        return

    if args[0] == "on":
        ok = ssh_ble(make_cmd(bytes([0x33, 0x01, 0x00])))
        print("Power on" if ok else "Failed")
        return

    if args[0] == "off":
        ok = ssh_ble(make_cmd(bytes([0x33, 0x01, 0x01])))
        print("Power off" if ok else "Failed")
        return

    if args[0] == "--brightness":
        b = int(args[1]) if len(args) > 1 else 50
        level = max(0, min(100, b))
        ok = ssh_ble(make_cmd(bytes([0x33, 0x04, level])))
        print(f"Brightness {b}%" if ok else "Failed")
        return

    r = g = b = 0
    brightness = 100
    hex_color = args[0].lstrip("#")
    if len(hex_color) >= 6:
        r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    if len(args) > 1:
        brightness = int(args[1])

    level = max(0, min(100, brightness))
    color = make_cmd(bytes([0x33, 0x05, 0x15, 0x01, r, g, b, 0, 0, 0, 0, 0, 0, 0xFF, 0x7F, 0, 0, 0, 0]))

    ok = ssh_ble(color)
    if ok:
        print(f"Set #{r:02x}{g:02x}{b:02x} at {brightness}% via Snowpi")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
