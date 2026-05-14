#!/bin/bash
########################################################################
##  SnowDots — Cursor Colors                              Version: v1.0.0    ##
##  Last Edited: 2026-05-14                                           ##
########################################################################

# Dynamic cursor color updater using matugen colors from wallpaper

CURSOR_DEST="$HOME/.local/share/icons/Future-Cyan"
FUZZEL_COLORS="$HOME/.cache/skwd-wall/fuzzel-colors.ini"
CURSOR_NAME="Future-Cyan"
CURSOR_SIZE=24

log() {
    echo "[cursor-colors] $(date '+%H:%M:%S') $1"
}

# Check if cursor theme exists
if [ ! -d "$CURSOR_DEST" ]; then
    log "Cursor theme not found: $CURSOR_DEST"
    exit 1
fi

# Check if matugen colors exist
if [ ! -f "$FUZZEL_COLORS" ]; then
    log "Matugen colors not found: $FUZZEL_COLORS"
    exit 1
fi

# Extract colors from fuzzel-colors.ini (matches matugen output)
PRIMARY=$(grep "^border=" "$FUZZEL_COLORS" | cut -d= -f2 | cut -c1-6)
SECONDARY=$(grep "^match=" "$FUZZEL_COLORS" | cut -d= -f2 | cut -c1-6)
ACCENT=$(grep "^selection=" "$FUZZEL_COLORS" | cut -d= -f2 | cut -c1-6)

# Default colors if extraction fails
[ -z "$PRIMARY" ] && PRIMARY="e4b7f3"
[ -z "$SECONDARY" ] && SECONDARY="a0d0c8"
[ -z "$ACCENT" ] && ACCENT="e4b7f3"

log "Primary: #$PRIMARY, Secondary: #$SECONDARY, Accent: #$ACCENT"

# Find all SVG files in cursor theme and replace colors
# Future-Cyan theme uses cyan (#23afc8) as main color - replace with matugen primary

find "$CURSOR_DEST" -name "*.svg" 2>/dev/null | while read svg; do
    sed -i \
        -e "s/#23afc8/#${PRIMARY}/g" \
        -e "s/#1a8fa3/${PRIMARY}CC/g" \
        -e "s/#2ac4d8/${PRIMARY}EE/g" \
        -e "s/#1694ad/${PRIMARY}99/g" \
        -e "s/#23AFc8/#${PRIMARY}/g" \
        -e "s/#1A8FA3/${PRIMARY}CC/g" \
        -e "s/#2AC4D8/${PRIMARY}EE/g" \
        -e "s/#1694AD/${PRIMARY}99/g" \
        "$svg"
done

log "Colors replaced in SVG files"

# Apply cursor
hyprctl setcursor "$CURSOR_NAME" "$CURSOR_SIZE" 2>/dev/null || true

log "Cursor colors updated: #$PRIMARY"