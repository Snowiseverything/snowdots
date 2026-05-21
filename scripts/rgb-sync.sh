#!/bin/bash

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"

ACCENT=$(jq -r '.accent' "$COLORS_FILE" 2>/dev/null)
if [ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ]; then
    exit 0
fi

COLOR="${ACCENT#\#}"

openrgb --mode static --color "$COLOR" --brightness 50 &>/dev/null
