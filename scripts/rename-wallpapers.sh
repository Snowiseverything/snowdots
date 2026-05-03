#!/bin/bash
# SnowDots — WallRenamer
WALL_DIR="$HOME/Pictures/Wallpapers"
cd "$WALL_DIR" || exit

counter=1
for file in *; do
    [ -d "$file" ] && continue
    [ "$file" == "$(basename "$0")" ] && continue

    new_name=$(printf "%03d.webp" "$counter")
    
    if [ "$file" != "$new_name" ]; then
        mv "$file" "$new_name"
    fi
    ((counter++))
done
echo "✅ Wallpapers in $WALL_DIR renamed."
