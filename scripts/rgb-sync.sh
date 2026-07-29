#!/bin/bash

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"

ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ]; then
	exit 0
fi

LED_COLOR=$(python3 -c "
import colorsys

hex_color = '${ACCENT}'.lstrip('#')
r = int(hex_color[0:2], 16) / 255.0
g = int(hex_color[2:4], 16) / 255.0
b = int(hex_color[4:6], 16) / 255.0

h, l, s = colorsys.rgb_to_hls(r, g, b)

# Unified LED color: same hue, vibrant saturation, medium brightness
# Looks good on case LEDs, keyboard, and Govee strip alike
r_l, g_l, b_l = colorsys.hls_to_rgb(h, 0.45, 0.90)
print('%02x%02x%02x' % (int(r_l*255), int(g_l*255), int(b_l*255)))
" 2>/dev/null)

[ -z "$LED_COLOR" ] && exit 0

# Run PC and Govee fades in parallel with matching step timing
# fade-rgb.py: 10 steps × 20ms = 200ms fade
# govee-led.py --fade: 10 steps × 20ms = 200ms fade via daemon socket
# Both finish at ~same time for synchronized color transition
timeout 10 python3 "$HOME/Dotfiles/scripts/fade-rgb.py" "$LED_COLOR" 80 2>&1 | sed 's/^/[PC] /' &

timeout 10 python3 "$HOME/Dotfiles/scripts/govee-led.py" "$LED_COLOR" 80 --fade 2>&1 | sed 's/^/[Govee] /' || echo "[Govee] failed or timed out" &

wait
