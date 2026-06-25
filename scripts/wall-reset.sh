#!/bin/bash
# wall-reset.sh — Sync RGB to current wallpaper colors (no wallpaper change)

ACCENT=$(jq -r '.accent' "$HOME/.cache/skwd-wall/colors.json" 2>/dev/null)
[ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ] && exit 1

curl -s -X POST http://localhost:5070/sync
