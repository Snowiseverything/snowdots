#!/bin/bash
# Extract wallpaper colors and apply to OpenRGB LEDs

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

# Get 4 dominant colors sorted by brightness (brightest first)
readarray -t PALETTE < <(
    magick "$WALLPAPER" -colors 4 -depth 8 -format "%c" histogram:info:- 2>/dev/null \
    | sort -rn | head -4 \
    | while read -r line; do
        HEX=$(echo "$line" | sed 's/.*#\([0-9A-Fa-f]\{6\}\).*/\1/')
        R=$((16#${HEX:0:2})); G=$((16#${HEX:2:2})); B=$((16#${HEX:4:2}))
        echo "$((R+G+B)) $HEX"
    done | sort -rn | awk '{print $2}'
)

# Filter out very dark colors (luminance < 40); use at least 1 color
FILTERED=()
for HEX in "${PALETTE[@]}"; do
    [ -z "$HEX" ] && continue
    R=$((16#${HEX:0:2})); G=$((16#${HEX:2:2})); B=$((16#${HEX:4:2}))
    MAX=$R; MIN=$R
    for v in "$G" "$B"; do
        [ "$v" -gt "$MAX" ] && MAX=$v
        [ "$v" -lt "$MIN" ] && MIN=$v
    done
    L=$(( (MAX + MIN) / 2 ))
    [ "$L" -ge 40 ] && FILTERED+=("$HEX")
done

# Fallback if everything filtered
if [ ${#FILTERED[@]} -eq 0 ]; then
    FILTERED=("${PALETTE[@]:0:1}")
fi

# Use only richest color for all LEDs to match wallpaper
openrgb --device 0 --mode static --color "${FILTERED[0]}" &>/dev/null
openrgb --device 1 --mode static --color "${FILTERED[0]}" &>/dev/null
openrgb --device 2 --mode static --color "${FILTERED[0]}" &>/dev/null
