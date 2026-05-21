#!/bin/bash
# Wait for matugen to finish, then apply saturated accent to OpenRGB

COLORS_FILE="$HOME/.config/skwd-wall/colors.json"
LAST_WALL="$HOME/.cache/skwd-wall/last-wallpaper.json"

# Record when this wallpaper was applied
WALL_MTIME=$(stat -c %Y "$LAST_WALL" 2>/dev/null || echo 0)

# Wait for colors.json to be newer than the wallpaper event
WAIT_START=$(date +%s)
while true; do
    if [ -f "$COLORS_FILE" ]; then
        COL_MTIME=$(stat -c %Y "$COLORS_FILE" 2>/dev/null || echo 0)
        [ "$COL_MTIME" -gt "$WALL_MTIME" ] && break
    fi
    sleep 0.3
    [ "$(($(date +%s) - WAIT_START))" -gt 15 ] && exit 0
done

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
