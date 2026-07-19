#!/bin/bash
# wall-reset.sh — always re-sync RGB to current wallpaper colors
# Bound to Super+Shift+W in hyprland.conf

CACHE="$HOME/.cache/skwd-wall"

ACCENT=$(jq -r '.accent' "$CACHE/colors.json" 2>/dev/null)
[ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ] && exit 1

curl -s -X POST http://localhost:5070/sync > /dev/null 2>&1
echo "$ACCENT" > "$CACHE/last_synced_accent"
notify-send -i "$CACHE/current-wallpaper" "RGB Sync" "Colors synced to wallpaper" 2>/dev/null
