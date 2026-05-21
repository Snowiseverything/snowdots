#!/bin/bash

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"

ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ]; then
    exit 0
fi

read -r FAN_COLOR RAM_COLOR <<< $(python3 -c "
import colorsys, sys

hex_color = '${ACCENT}'.lstrip('#')
r = int(hex_color[0:2], 16) / 255.0
g = int(hex_color[2:4], 16) / 255.0
b = int(hex_color[4:6], 16) / 255.0

h, _, _ = colorsys.rgb_to_hls(r, g, b)

# Fans: accent hue, 35% lightness, 80% saturation
r1, g1, b1 = colorsys.hls_to_rgb(h, 0.35, 0.80)
fan = '%02x%02x%02x' % (int(r1*255), int(g1*255), int(b1*255))

# RAM: -20° hue shift, 30% lightness, 90% saturation (ENE calibration)
h_ram = h - 20.0 / 360.0
if h_ram < 0:
    h_ram += 1.0
r2, g2, b2 = colorsys.hls_to_rgb(h_ram, 0.30, 0.90)
ram = '%02x%02x%02x' % (int(r2*255), int(g2*255), int(b2*255))

print(f'{fan} {ram}')
" 2>/dev/null)

[ -z "$FAN_COLOR" ] && exit 0

openrgb --device 0 --mode static --color "$RAM_COLOR" --brightness 50 &>/dev/null
openrgb --device 1 --mode static --color "$RAM_COLOR" --brightness 50 &>/dev/null
openrgb --device 2 --mode static --color "$FAN_COLOR" --brightness 50 &>/dev/null
