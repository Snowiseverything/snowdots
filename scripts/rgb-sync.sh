#!/bin/bash
# Normalize matugen accent to fully saturated color, apply to OpenRGB LEDs

COLORS_FILE="$HOME/.config/skwd-wall/colors.json"

if [ ! -f "$COLORS_FILE" ]; then
    exit 0
fi

ACCENT=$(jq -r '.accent' "$COLORS_FILE")
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ]; then
    exit 0
fi

HEX="${ACCENT#\#}"
R=$((16#${HEX:0:2})); G=$((16#${HEX:2:2})); B=$((16#${HEX:4:2}))

MIN=$R; MAX=$R
for v in "$G" "$B"; do
    [ "$v" -lt "$MIN" ] && MIN=$v
    [ "$v" -gt "$MAX" ] && MAX=$v
done

RANGE=$((MAX - MIN))
[ "$RANGE" -lt 5 ] && RANGE=5

R=$(( (R - MIN) * 255 / RANGE ))
G=$(( (G - MIN) * 255 / RANGE ))
B=$(( (B - MIN) * 255 / RANGE ))

COLOR=$(printf "%02x%02x%02x" "$R" "$G" "$B")

openrgb --device 0 --mode static --color "$COLOR" &>/dev/null
openrgb --device 1 --mode static --color "$COLOR" &>/dev/null
openrgb --device 2 --mode static --color "$COLOR" &>/dev/null
