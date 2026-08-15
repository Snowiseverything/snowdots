#!/bin/bash
# wall-reset.sh — always re-sync RGB to current wallpaper colors
# Bound to Super+Shift+W in hyprland.lua
# Also runs at boot via exec-once in hyprland.lua

DEBOUNCE_FILE="/tmp/wall-reset-debounce"
DEBOUNCE_MS=2000

now=$(date +%s%3N)
if [ -f "$DEBOUNCE_FILE" ]; then
	last=$(cat "$DEBOUNCE_FILE")
	if [ "$((now - last))" -lt "$DEBOUNCE_MS" ]; then
		exit 0
	fi
fi
echo "$now" >"$DEBOUNCE_FILE"

CACHE="$HOME/.cache/skwd-wall"

ACCENT=$(jq -r '.accent' "$CACHE/colors.json" 2>/dev/null)
[ -z "$ACCENT" ] || [ "$ACCENT" = "null" ] || [ "$ACCENT" = "#000000" ] && exit 1

# Try bridge first, fall back to direct rgb-sync
resp=$(curl -sf -X POST http://localhost:5070/sync 2>/dev/null)
if [ -n "$resp" ]; then
	msg=$(echo "$resp" | jq -r '.message // "Colors synced to wallpaper"')
	notify-send -i "$CACHE/current-wallpaper" "RGB Sync" "$msg" 2>/dev/null
else
	notify-send -i "$CACHE/current-wallpaper" "RGB Sync" "Colors synced to wallpaper" 2>/dev/null
	bash "$HOME/Dotfiles/scripts/rgb-sync.sh" >/dev/null 2>&1 &
fi

echo "$ACCENT" >"$CACHE/last_synced_accent"
