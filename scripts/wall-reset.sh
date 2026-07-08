#!/bin/bash
# wall-reset.sh — Sync RGB to current wallpaper colors (no wallpaper change)

CACHE="$HOME/.cache/skwd-wall"
SYNCED_FILE="$CACHE/last_synced_accent"

ACCENT=$(jq -r '.accent' "$CACHE/colors.json" 2>/dev/null)
[ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ] && exit 1

if [ -f "$SYNCED_FILE" ] && [ "$(cat "$SYNCED_FILE")" = "$ACCENT" ]; then
    notify-send -i "$CACHE/current-wallpaper" "RGB Sync" "Already synced to current wallpaper" 2>/dev/null
    exit 0
fi

curl -s -X POST http://localhost:5070/sync > /dev/null 2>&1
echo "$ACCENT" > "$SYNCED_FILE"
notify-send -i "$CACHE/current-wallpaper" "RGB Sync" "Colors synced to wallpaper" 2>/dev/null
