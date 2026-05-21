#!/bin/bash
# Extract wallpaper colors and apply vibrant LED colors to OpenRGB

LAST_WALL="$HOME/.cache/skwd-wall/last-wallpaper.json"
CURRENT_JPG="$HOME/.cache/skwd-wall/wallpaper/current.jpg"

if [ -f "$LAST_WALL" ]; then
    WALLPAPER=$(jq -r '.path' "$LAST_WALL")
elif [ -f "$CURRENT_JPG" ]; then
    WALLPAPER="$CURRENT_JPG"
else
    exit 0
fi

[ -z "$WALLPAPER" ] && exit 0

# Get 4 dominant colors, sort by brightness
readarray -t PALETTE < <(
    magick "$WALLPAPER" -colors 4 -depth 8 -format "%c" histogram:info:- 2>/dev/null \
    | sort -rn | head -4 \
    | while read -r line; do
        HEX=$(echo "$line" | sed 's/.*#\([0-9A-Fa-f]\{6\}\).*/\1/')
        R=$((16#${HEX:0:2})); G=$((16#${HEX:2:2})); B=$((16#${HEX:4:2}))
        echo "$((R+G+B)) $HEX"
    done | sort -rn | awk '{print $2}'
)

# Boost dark colors to be vibrant on LEDs
VIBRANT=()
for HEX in "${PALETTE[@]}"; do
    [ -z "$HEX" ] && continue
    R=$((16#${HEX:0:2})); G=$((16#${HEX:2:2})); B=$((16#${HEX:4:2}))
    MAX=$R; MIN=$R
    for v in "$G" "$B"; do
        [ "$v" -gt "$MAX" ] && MAX=$v
        [ "$v" -lt "$MIN" ] && MIN=$v
    done
    L=$(( (MAX + MIN) / 2 ))
    if [ "$L" -lt 80 ] && [ "$MAX" -gt 0 ]; then
        SCALE=$(echo "scale=2; 180 / $MAX" | bc 2>/dev/null)
        SCALE=${SCALE:-1.5}
        R=$(echo "($R * $SCALE + 0.5) / 1" | bc 2>/dev/null)
        G=$(echo "($G * $SCALE + 0.5) / 1" | bc 2>/dev/null)
        B=$(echo "($B * $SCALE + 0.5) / 1" | bc 2>/dev/null)
        [ "$R" -gt 255 ] && R=255
        [ "$G" -gt 255 ] && G=255
        [ "$B" -gt 255 ] && B=255
    fi
    VIBRANT+=($(printf "%02x%02x%02x" "$R" "$G" "$B"))
done

# Fallback
if [ ${#VIBRANT[@]} -eq 0 ]; then
    VIBRANT=("88ceff" "6e92a6" "4a6a80" "314251")
fi

# DRAM sticks: brightest/richest color
openrgb --device 0 --mode static --color "${VIBRANT[0]}" &>/dev/null
openrgb --device 1 --mode static --color "${VIBRANT[0]}" &>/dev/null

# Motherboard per zone
for i in 0 1 2 3; do
    idx=$((i < ${#VIBRANT[@]} ? i : ${#VIBRANT[@]} - 1))
    openrgb --device 2 --zone "$i" --mode static --color "${VIBRANT[$idx]}" &>/dev/null
done
