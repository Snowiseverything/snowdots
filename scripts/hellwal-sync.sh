#!/usr/bin/env bash
# Run hellwal with wallpaper, copy outputs to config paths, reload apps

set +euo pipefail 2>/dev/null || true
set -o pipefail 2>/dev/null || true

WALLPAPER="${1:-}"
[ -z "$WALLPAPER" ] && echo "Usage: hellwal-sync.sh <wallpaper_path>" && exit 1

# Run hellwal (don't fail if it errors)
hellwal -i "$WALLPAPER" 2>&1 || true

CACHE="$HOME/.cache/hellwal"

# Map template filename → target config path
declare -A MAP
MAP["hyprlock-colors.conf"]="$HOME/.config/hypr/hyprlock/matugen/matugen-hyprlock.conf"
MAP["rofi-colors.rasi"]="$HOME/.config/rofi/launchers/styles/shared/colors.rasi"
MAP["wlogout.css"]="$HOME/.config/wlogout/style.css"
MAP["colors.json"]="$HOME/.cache/skwd-wall/colors.json"
MAP["hyprland-colors.conf"]="$HOME/.cache/skwd-wall/hyprland-colors.conf"
MAP["kitty-colors.conf"]="$HOME/.cache/skwd-wall/colors-kitty.conf"
MAP["theme.css"]="$HOME/.cache/skwd-wall/theme.css"
MAP["opencode.json"]="$HOME/.config/opencode/themes/matugen.json"
MAP["starship.toml"]="$HOME/.config/starship.toml"
MAP["gtk.css"]="$HOME/.config/gtk-3.0/gtk.css"
MAP["swaync.css"]="$HOME/.cache/skwd-wall/swaync.css"
MAP["caelestia-scheme.json"]="$HOME/.local/state/caelestia/scheme.json"
MAP["fuzzel-colors.ini"]="$HOME/.cache/skwd-wall/fuzzel-colors.ini"
MAP["spicetify.ini"]="$HOME/.config/spicetify/Themes/Matugen/color.ini"

for src in "${!MAP[@]}"; do
	dst="${MAP[$src]}"
	if [ -f "$CACHE/$src" ]; then
		mkdir -p "$(dirname "$dst")"
		cp "$CACHE/$src" "$dst"
	else
		echo "Warning: $CACHE/$src not found, skipping $dst"
	fi
done

# Also copy gtk4
if [ -f "$CACHE/gtk.css" ]; then
	cp "$CACHE/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
fi

# Reload apps
hyprctl reload 2>/dev/null || true
pkill -USR1 kitty 2>/dev/null || true
killall -SIGUSR2 swaync 2>/dev/null || true
pkill -USR2 waybar 2>/dev/null || true

# Restart caelestia so it re-reads scheme
if pgrep -f "qs -c caelestia" >/dev/null 2>&1; then
	pkill -f "qs -c caelestia" 2>/dev/null || true
	rm -rf "/run/user/$(id -u)/quickshell/by-id/"* 2>/dev/null || true
	sleep 0.3
	caelestia shell -d &
fi

# Notify if in graphical session
if [ -n "$WAYLAND_DISPLAY" ]; then
	notify-send "Hellwal" "Theme updated from $(basename "$WALLPAPER")" 2>/dev/null || true
fi
