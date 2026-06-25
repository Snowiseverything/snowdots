#!/usr/bin/env bash
# Pick and apply a favorite wallpaper via fuzzel

WALLS=$(skwd wall list)
FAVS=$(echo "$WALLS" | python3 -c "
import json, sys, os
data = json.load(sys.stdin)
favs = [w for w in data['wallpapers'] if w.get('favourite') == 1]
for w in favs:
    thumb = w.get('thumb_sm') or w.get('thumb', '')
    name = w['name']
    print(f'{name}')
")

[ -z "$FAVS" ] && notify-send "No favorites" "No favorite wallpapers set" && exit 1

CHOICE=$(echo "$FAVS" | fuzzel --dmenu --minimal-lines -p "Favorite:")
[ -z "$CHOICE" ] && exit 1

skwd wall apply "{\"name\":\"$CHOICE\"}"
notify-send "Wallpaper" "Applied: $CHOICE"
