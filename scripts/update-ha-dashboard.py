#!/usr/bin/env python3
"""Update HA dashboard to add Freezer RGB controls."""
import json, subprocess, sys

HA_URL = "http://100.83.33.67:8123"
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI0YjMzZDI1M2I2OTc0MDUwYTIxM2MwNDdkMWZjODVmNCIsImlhdCI6MTc4MTg1NTQzMywiZXhwIjoyMDk3MjE1NDMzfQ.xIE4jtuBiB1c2OtmYn7-F-y5gsw2V7DoVWQ66WhTNmU"

# Read the current dashboard config
config = subprocess.run(
    ["docker", "exec", "homeassistant", "cat", "/config/.storage/lovelace.dashboard_home"],
    capture_output=True, text=True, cwd="/"
)
dashboard = json.loads(config.stdout)

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
