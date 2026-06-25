#!/usr/bin/env bash

CACHE_DIR="${HOME}/.cache/skwd-wall"
KITTY_CACHE="${CACHE_DIR}/colors-kitty.conf"

if [[ -f "$KITTY_CACHE" ]]; then
    C1=$(grep -E "^color1\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C2=$(grep -E "^color2\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C4=$(grep -E "^color4\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C9=$(grep -E "^color9\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    echo "$C1 $C2 $C4 $C9"
else
    echo "default"
fi