#!/bin/bash
# papirus-folder-sync.sh — map matugen accent to closest papirus-folders color
# Called by wall-sync.sh after wallpaper change

CACHE="$HOME/.cache/skwd-wall"
COLORS="$CACHE/colors.json"
[ -f "$COLORS" ] || exit 0

# Extract primary hex color (strip #)
PRIMARY=$(jq -r '.primary' "$COLORS" 2>/dev/null | tr -d '#')
[ -n "$PRIMARY" ] && [ "$PRIMARY" != "null" ] || exit 0

# Closest papirus-folders color name by hue
# Map hex -> named color based on hue ranges
map_color() {
    local hex="$1"
    local r g b h s l
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    
    # HSV-ish approximation
    local max=$r min=$r
    [ $g -gt $max ] && max=$g
    [ $b -gt $max ] && max=$b
    [ $g -lt $min ] && min=$g
    [ $b -lt $min ] && min=$b
    
    local delta=$((max - min))
    
    # Lightness
    l=$(( (max + min) / 2 ))
    
    # Saturation
    if [ $delta -eq 0 ]; then
        echo "grey"
        return
    fi
    s=$(( (delta * 255) / (255 - $(( (l > 127) ? ( (2 * (255 - $l)) / 255) : ( (2 * $l) / 255) )) ) ))
    
    # Hue
    if [ $max -eq $r ]; then
        h=$(( ( (g - b) * 60 / delta + 360 ) % 360 ))
    elif [ $max -eq $g ]; then
        h=$(( (b - r) * 60 / delta + 120 ))
    else
        h=$(( (r - g) * 60 / delta + 240 ))
    fi
    
    # Map hue to color name
    if [ $h -lt 20 ] || [ $h -ge 345 ]; then
        echo "red"
    elif [ $h -lt 45 ]; then
        echo "orange"
    elif [ $h -lt 75 ]; then
        echo "yellow"
    elif [ $h -lt 150 ]; then
        echo "green"
    elif [ $h -lt 200 ]; then
        echo "teal"
    elif [ $h -lt 260 ]; then
        echo "blue"
    elif [ $h -lt 300 ]; then
        echo "violet"
    elif [ $h -lt 345 ]; then
        echo "magenta"
    else
        echo "red"
    fi
}

FOLDER_COLOR=$(map_color "$PRIMARY")

LOCAL_THEME="$HOME/.local/share/icons/Papirus-FolderColor"

# Pre-flight: resolve any symlinked folder-$color-*.svg to real files
# papirus-folders skips symlinks, so they must be real files first
for size in 22x22 24x24 32x32 48x48 64x64; do
    places="$LOCAL_THEME/$size/places"
    [ -d "$places" ] || continue
    for f in "$places"/folder-"$FOLDER_COLOR"-*.svg; do
        [ -L "$f" ] || continue
        target=$(readlink -f "$f")
        if [ -f "$target" ]; then
            rm -f "$f"
            cp "$target" "$f"
        fi
    done
done

# Apply via papirus-folders (local copy to avoid sudo)
if command -v papirus-folders &>/dev/null; then
    papirus-folders -C "$FOLDER_COLOR" --theme "$LOCAL_THEME" 2>&1
    echo "papirus-folders: set $FOLDER_COLOR"
    gtk-update-icon-cache -f "$LOCAL_THEME" 2>/dev/null || true
else
    echo "papirus-folders not installed"
fi
