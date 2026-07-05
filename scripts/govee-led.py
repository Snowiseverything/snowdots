#!/usr/bin/env python3
"""Control Govee LED strip via Home Assistant API.

Usage:
  govee-led.py <hex_color>               # set color (e.g. ff00ff)
  govee-led.py --brightness <0-100>      # set brightness
  govee-led.py on | off                  # power on/off
  govee-led.py discover                  # scan for HA Govee entities
"""
import sys, urllib.request, json
from pathlib import Path

CONFIG = Path.home() / ".config/govee-led.toml"
HA_URL = "http://100.83.33.67:8123"
HA_TOKEN = ""
ENTITY = "light.govee_h6102_2f48"

# Read token from config file
if CONFIG.exists():
    for line in CONFIG.read_text().splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            k, v = k.strip(), v.strip().strip('"')
            if k == "ha_token":
                HA_TOKEN = v
            elif k == "entity":
                ENTITY = v

def ha_call(endpoint, data=None):
    req = urllib.request.Request(
        f"{HA_URL}/api/{endpoint}",
        data=json.dumps(data).encode() if data else None,
        headers={
            "Authorization": f"Bearer {HA_TOKEN}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())

def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__.strip())
        return

    if args[0] == "discover":
        r = ha_call("states")
        for s in r:
            if "govee" in s.get("entity_id", "").lower():
                eid = s["entity_id"]
                state = s.get("state", "?")
                color = s.get("attributes", {}).get("rgb_color", "?")
                print(f"{eid}: {state} rgb={color}")
        return

    if args[0] == "on":
        ha_call(f"services/light/turn_on", {"entity_id": ENTITY})
        print("Power on")
        return

    if args[0] == "off":
        ha_call(f"services/light/turn_off", {"entity_id": ENTITY})
        print("Power off")
        return

    if args[0] == "--brightness":
        b = int(args[1]) if len(args) > 1 else 50
        pct = max(1, min(100, b))
        ha_call(f"services/light/turn_on", {"entity_id": ENTITY, "brightness_pct": pct})
        print(f"Brightness {pct}%")
        return

    r = g = b = 0
    brightness = 100
    hex_color = args[0].lstrip("#")
    if len(hex_color) >= 6:
        r, g, b = int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16)
    if len(args) > 1:
        brightness = int(args[1])

    pct = max(1, min(100, brightness))
    ha_call(f"services/light/turn_on", {"entity_id": ENTITY, "rgb_color": [r, g, b], "brightness_pct": pct})
    print(f"Set #{r:02x}{g:02x}{b:02x} at {pct}% via HA")

if __name__ == "__main__":
    main()
