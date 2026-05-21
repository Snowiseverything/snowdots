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

HEX="${ACCENT#\#}"
R=$((16#${HEX:0:2}))
G=$((16#${HEX:2:2}))
B=$((16#${HEX:4:2}))

for dev in 0 1 2; do
    openrgb --device "$dev" --mode direct --color "$R" "$G" "$B" 2>/dev/null
done
