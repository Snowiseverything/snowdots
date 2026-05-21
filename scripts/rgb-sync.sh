#!/bin/bash
# Boost accent saturation moderately for LEDs, apply to OpenRGB

COLORS_FILE="$HOME/.config/skwd-wall/colors.json"

ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
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
if [ "$RANGE" -gt 5 ]; then
    # Partial normalization: blend 70% toward fully saturated
    RN=$(( (R - MIN) * 255 / RANGE ))
    GN=$(( (G - MIN) * 255 / RANGE ))
    BN=$(( (B - MIN) * 255 / RANGE ))
    R=$(( R + (RN - R) * 70 / 100 ))
    G=$(( G + (GN - G) * 70 / 100 ))
    B=$(( B + (BN - B) * 70 / 100 ))
fi

COLOR=$(printf "%02x%02x%02x" "$R" "$G" "$B")

openrgb --device 0 --mode static --color "$COLOR" &>/dev/null
openrgb --device 1 --mode static --color "$COLOR" &>/dev/null
openrgb --device 2 --mode static --color "$COLOR" &>/dev/null
