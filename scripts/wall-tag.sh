#!/bin/bash
###########################################################################
##  SnowDots — WallTag                             Version: v1.0.0    ##
##  Last Edited: 2026-05-06                                              ##
##  Tags wallpapers using Ollama vision model                            ##
###########################################################################

# Configuration
OLLAMA_MODEL="llava"
TAGS_DIR="$HOME/.local/share/wall-sync/tags"
LOG_DIR="$HOME/.local/share/wall-sync/logs"
LOG_FILE="$LOG_DIR/wall-tag.log"

mkdir -p "$TAGS_DIR" "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if ollama is running
check_ollama() {
    if ! pgrep -x "ollama" > /dev/null; then
        log "Starting ollama..."
        ollama serve &
        sleep 3
    fi
}

# Check if model is available
check_model() {
    if ! ollama list | grep -q "$OLLAMA_MODEL"; then
        log "Pulling model: $OLLAMA_MODEL"
        ollama pull "$OLLAMA_MODEL"
    fi
}

# Tag a wallpaper image
tag_wallpaper() {
    local WALLPAPER="$1"
    
    if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
        log "Error: Wallpaper not found: $WALLPAPER"
        echo "Error: Wallpaper not found"
        return 1
    fi
    
    local BASENAME=$(basename "$WALLPAPER")
    local TAG_FILE="$TAGS_DIR/${BASENAME%.webp}.txt"
    
    log "Tagging: $WALLPAPER"
    
    # Use describeimage if available, otherwise use ollama directly
    if command -v describeimage &> /dev/null; then
        TAGS=$(describeimage "$WALLPAPER" 2>/dev/null | head -5)
    else
        # Prompt for concise tags
        TAGS=$(echo "Describe this image in 5-8 keywords, like: nature, forest, mountains, blue sky, sunset. Be brief." | ollama run "$OLLAMA_MODEL" "$WALLPAPER" 2>/dev/null | head -10)
    fi
    
    if [ -n "$TAGS" ]; then
        echo "$TAGS" > "$TAG_FILE"
        log "Tags saved to: $TAG_FILE"
        echo "Tags: $TAGS"
    else
        log "Failed to generate tags"
        echo "Failed to generate tags"
        return 1
    fi
}

# Main
case "${1:-}" in
    -h|--help)
        echo "Usage: wall-tag.sh <wallpaper-path>"
        echo "       wall-tag.sh --tag-all"
        echo ""
        echo "Options:"
        echo "  <wallpaper-path>  Tag a specific wallpaper"
        echo "  --tag-all         Tag all wallpapers in ~/Pictures/Wallpapers"
        exit 0
        ;;
    --tag-all)
        log "Tagging all wallpapers..."
        for wall in ~/Pictures/Wallpapers/*.webp ~/Pictures/Wallpapers/*.jpg ~/Pictures/Wallpapers/*.png; do
            [ -f "$wall" ] && tag_wallpaper "$wall"
        done
        log "Finished tagging all wallpapers"
        ;;
    *)
        if [ -n "$1" ]; then
            check_ollama
            check_model
            tag_wallpaper "$1"
        else
            echo "Usage: wall-tag.sh <wallpaper-path>"
            echo "Run --help for more options"
        fi
        ;;
esac