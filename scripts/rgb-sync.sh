#!/bin/bash
# Apply matugen accent color to all OpenRGB LEDs
# Called by skwd-wall after wallpaper change

COLORS_FILE="$HOME/.config/skwd-wall/colors.json"

if [ ! -f "$COLORS_FILE" ]; then
    exit 0
fi

ACCENT=$(jq -r '.accent' "$COLORS_FILE")
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ]; then
    exit 0
fi

COLOR="${ACCENT#\#}"

for dev in 0 1 2; do
    openrgb --device "$dev" --mode direct --color "$COLOR" &>/dev/null
done
