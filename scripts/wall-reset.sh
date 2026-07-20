#!/bin/bash
# wall-reset.sh — always re-sync RGB to current wallpaper colors
# Bound to Super+Shift+W in hyprland.conf
# Also runs at boot via exec-once in hyprland.conf

CACHE="$HOME/.cache/skwd-wall"

ACCENT=$(jq -r '.accent' "$CACHE/colors.json" 2>/dev/null)
[ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ] && exit 1

notify-send -i "$CACHE/current-wallpaper" "RGB Sync" "Colors synced to wallpaper" 2>/dev/null

# Try bridge first, fall back to direct rgb-sync
if ! curl -sf -X POST http://localhost:5070/sync > /dev/null 2>&1; then
    bash "$HOME/Dotfiles/scripts/rgb-sync.sh" > /dev/null 2>&1 &
fi

echo "$ACCENT" > "$CACHE/last_synced_accent"
