#!/bin/bash
set -euo pipefail

WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"
CACHE_FILE="/tmp/skwd-favs.cache"

# Get favorite wallpapers from skwd, cache for 60s
if [ -f "$CACHE_FILE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE_FILE") )) -lt 60 ]; then
    FAVS=$(cat "$CACHE_FILE")
else
    FAVS=$(skwd wall list 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
for w in d.get('wallpapers',[]):
    if w.get('favourite') and w.get('path'):
        print(f\"{w['path']}|{w['name']}\")
" 2>/dev/null || true)
    [ -n "$FAVS" ] && echo "$FAVS" > "$CACHE_FILE"
fi

if [ -z "$FAVS" ]; then
    notify-send "Wallpaper" "No favorites found. Add some in skwd first."
    exit 1
fi

# Use fzf to select
PICKED=$(echo "$FAVS" | awk -F'|' '{print $2 "  →  " $1}' | fzf \
    --prompt="Fav Wallpaper > " \
    --preview="echo {} | awk -F'  →  ' '{print \$2}' | xargs -I{} sh -c 'kitten icat --clear --place 80x40@0x0 \"{}\" 2>/dev/null || echo Preview: {}'" \
    --preview-window=right:55% \
    --height=70%)

[ -z "$PICKED" ] && exit 0

WALL=$(echo "$PICKED" | awk -F'  →  ' '{print $2}')
[ -z "$WALL" ] && exit 0
WALL=$(echo "$WALL" | xargs)

if [ ! -f "$WALL" ]; then
    notify-send "Wallpaper" "File not found: $WALL"
    exit 1
fi

# Apply via awww + matugen + rgb-sync
awww img "$WALL" --transition-type wipe --transition-angle 30
matugen image "$WALL" --source-color-index 0 2>/dev/null
bash "$HOME/Dotfiles/scripts/rgb-sync.sh" &>/dev/null

WALL_NAME=$(basename "$WALL")
notify-send -i "$WALL" "Wallpaper Changed" "Applied: $WALL_NAME" 2>/dev/null || true
