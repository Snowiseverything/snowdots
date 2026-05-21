#!/bin/bash
# Boost accent to vibrant color while preserving exact hue, apply to OpenRGB

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"

ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ]; then
    exit 0
fi

COLOR=$(python3 -c "
import colorsys

hex_color = '${ACCENT}'.lstrip('#')
r = int(hex_color[0:2], 16) / 255.0
g = int(hex_color[2:4], 16) / 255.0
b = int(hex_color[4:6], 16) / 255.0

h, l, s = colorsys.rgb_to_hls(r, g, b)
r2, g2, b2 = colorsys.hls_to_rgb(h, 0.40, 0.75)
r2 = max(0, min(255, int(r2 * 255 + 0.5)))
g2 = max(0, min(255, int(g2 * 255 + 0.5)))
b2 = max(0, min(255, int(b2 * 255 + 0.5)))
print(f'{r2:02x}{g2:02x}{b2:02x}')
" 2>/dev/null)

[ -z "$COLOR" ] && exit 0

openrgb --device 0 --mode static --color "$COLOR" &>/dev/null
openrgb --device 1 --mode static --color "$COLOR" &>/dev/null
openrgb --device 2 --mode static --color "$COLOR" &>/dev/null
