#!/usr/bin/env python3
"""Update HA dashboard to add Freezer RGB controls."""
import json, os, subprocess, sys
from pathlib import Path

HA_URL = "http://<ha-ip>:8123"

# Read token from same config as govee-led.py
_config = Path.home() / ".config/govee-led.toml"
TOKEN = ""
if _config.exists():
    for line in _config.read_text().splitlines():
        if line.startswith("ha_token"):
            TOKEN = line.split("=", 1)[1].strip().strip('"')

# Read the current dashboard config
try:
    config = subprocess.run(
        ["docker", "exec", "homeassistant", "cat", "/config/.storage/lovelace.dashboard_home"],
        capture_output=True, text=True, cwd="/"
    )
    config.check_returncode()
except (subprocess.CalledProcessError, FileNotFoundError) as e:
    print(f"Error reading dashboard config: {e}")
    sys.exit(1)

try:
    dashboard = json.loads(config.stdout)
except json.JSONDecodeError as e:
    print(f"Error parsing dashboard config: {e}")
    sys.exit(1)

# The Govee section to replace
govee_section = dashboard["data"]["config"]["views"][0]["sections"][-1]

# Replace with RGB section
govee_section["title"] = "Freezer RGB"
govee_section["cards"][0] = {
    "type": "heading",
    "heading": "PC RGB"
}

govee_section["cards"].extend([
    {
        "type": "tile",
        "entity": "light.govee_h6102_2f48",
        "name": "Govee Strip",
        "icon": "mdi:led-strip"
    },
    {
        "type": "tile",
        "entity": "sensor.freezer_rgb_2",
        "name": "OpenRGB + Keyboard",
        "icon": "mdi:desktop-tower-monitor"
    },
    {
        "type": "grid",
        "columns": 6,
        "cards": [
            {
                "type": "button",
                "name": "",
                "icon": "mdi:circle",
                "icon_color": "#ff6600",
                "tap_action": {
                    "action": "call-service",
                    "service": "rest_command.rgb_all",
                    "data": {"color": "ff6600", "brightness": 70}
                }
            },
            {
                "type": "button",
                "name": "",
                "icon": "mdi:circle",
                "icon_color": "#00aaff",
                "tap_action": {
                    "action": "call-service",
                    "service": "rest_command.rgb_all",
                    "data": {"color": "00aaff", "brightness": 70}
                }
            },
            {
                "type": "button",
                "name": "",
                "icon": "mdi:circle",
                "icon_color": "#ff0066",
                "tap_action": {
                    "action": "call-service",
                    "service": "rest_command.rgb_all",
                    "data": {"color": "ff0066", "brightness": 70}
                }
            },
            {
                "type": "button",
                "name": "",
                "icon": "mdi:circle",
                "icon_color": "#00ff88",
                "tap_action": {
                    "action": "call-service",
                    "service": "rest_command.rgb_all",
                    "data": {"color": "00ff88", "brightness": 70}
                }
            },
            {
                "type": "button",
                "name": "",
                "icon": "mdi:circle",
                "icon_color": "#ffaa00",
                "tap_action": {
                    "action": "call-service",
                    "service": "rest_command.rgb_all",
                    "data": {"color": "ffaa00", "brightness": 70}
                }
            },
            {
                "type": "button",
                "name": "",
                "icon": "mdi:circle",
                "icon_color": "#aa00ff",
                "tap_action": {
                    "action": "call-service",
                    "service": "rest_command.rgb_all",
                    "data": {"color": "aa00ff", "brightness": 70}
                }
            }
        ]
    },
    {
        "type": "button",
        "name": "Sync with Wallpaper",
        "icon": "mdi:wallpaper",
        "tap_action": {
            "action": "call-service",
            "service": "rest_command.rgb_sync"
        }
    },
    {
        "type": "button",
        "name": "All Off",
        "icon": "mdi:power",
        "tap_action": {
            "action": "call-service",
            "service": "rest_command.rgb_all",
            "data": {"color": "000000", "brightness": 0}
        }
    }
])

# Write back
subprocess.run(
    ["docker", "exec", "-i", "homeassistant", "sh", "-c", "cat > /config/.storage/lovelace.dashboard_home"],
    input=json.dumps(dashboard, indent=2).encode(),
    cwd="/"
)

print("Dashboard updated")
