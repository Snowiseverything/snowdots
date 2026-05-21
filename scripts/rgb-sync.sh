#!/bin/bash

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"

ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ]; then
    exit 0
fi

COLOR=$(python3 -c "
import colorsys

hex_color = '${ACCENT}'.lstrip('#')
r = int(hex_color[0:2], 16) / 255.0
g = int(hex_color[2:4], 16) / 255.0
b = int(hex_color[4:6], 16) / 255.0

h, _, _ = colorsys.rgb_to_hls(r, g, b)
r2, g2, b2 = colorsys.hls_to_rgb(h, 0.28, 0.80)
print('%02x%02x%02x' % (int(r2*255), int(g2*255), int(b2*255)))
" 2>/dev/null)

[ -z "$COLOR" ] && exit 0

openrgb --mode static --color "$COLOR" --brightness 50 &>/dev/null
python3 "$HOME/.local/bin/mad68-rgb.py" "$COLOR" &>/dev/null
