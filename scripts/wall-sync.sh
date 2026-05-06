#!/bin/bash 
###########################################################################
##  SnowDots — SnowWallsync                              Version: v1.1.4 ##
##  Last Edited: 2026-05-06                                              ##
###########################################################################

# Logging setup
LOG_DIR="$HOME/.local/share/wall-sync/logs"
LOG_FILE="$LOG_DIR/wall-sync.log"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
}

# Log script start with environment info for boot debugging
log "=== Wall-sync started ==="
log "USER=$USER HOME=$HOME XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
log "Args: $@"

# Ensure XDG_RUNTIME_DIR is set
[ -z "$XDG_RUNTIME_DIR" ] && export XDG_RUNTIME_DIR="/run/user/$(id -u)"
log "XDG_RUNTIME_DIR set to: $XDG_RUNTIME_DIR"

# 1. Daemon Check
# Ensure awww-daemon is running (used by skwd)
if ! pgrep -x "awww-daemon" > /dev/null; then
    log "Starting awww-daemon..."
    rm -f "$XDG_RUNTIME_DIR/awww.socket"
    awww-daemon --format xrgb &
    sleep 0.5
else
    log "awww-daemon already running"
fi

# Ensure skwd-daemon is running
if ! pgrep -x "skwd-daemon" > /dev/null; then
    log "Starting skwd-daemon..."
    rm -f "$XDG_RUNTIME_DIR/skwd/daemon.sock"
    skwd-daemon > /dev/null 2>&1 &
    sleep 0.5
else
    log "skwd-daemon already running"
fi

# 2. Path Definitions
CACHE_DIR="$HOME/.cache/skwd-wall"
LAST_WALL_FILE="$CACHE_DIR/last_applied_wall.txt"
mkdir -p "$CACHE_DIR"

# 3. Determine Wallpaper Path
# Priority: Argument ($1) from Matugen > Awww Query > Last Known Good > Fallback
if [ -n "$1" ] && [ -f "$1" ]; then
    WALLPAPER="$1"
else
    WALLPAPER=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | tr -d '[:space:]')
fi

# Apply fallback logic if query fails
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ] || [[ "$WALLPAPER" == *"lucy"* ]]; then
    if [ -f "$LAST_WALL_FILE" ]; then
        WALLPAPER=$(cat "$LAST_WALL_FILE")
    else
        WALLPAPER="$HOME/Pictures/Wallpapers/272.webp"
    fi
fi

# Validate wallpaper exists
if [ ! -f "$WALLPAPER" ]; then
    log_error "Wallpaper not found: $WALLPAPER, using fallback"
    WALLPAPER="$HOME/Pictures/Wallpapers/272.webp"
fi

log "Using wallpaper: $WALLPAPER"

# Save as the "Last Known Good"
echo "$WALLPAPER" > "$LAST_WALL_FILE"

# Generate colors from new wallpaper using matugen
log "Running matugen..."
if matugen image "$WALLPAPER" --source-color-index 0 2>>"$LOG_FILE"; then
    log "Matugen completed successfully"
else
    log_error "Matugen failed (non-fatal, continuing)"
fi

# 4. Apply the Image
# Only transitions if the wallpaper actually changed
CURRENT_ON_SCREEN=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')
if [ "$WALLPAPER" != "$CURRENT_ON_SCREEN" ]; then
    awww img "$WALLPAPER" --transition-type wipe --transition-angle 30 || \
    swww img "$WALLPAPER" --outputs DP-2 --transition-type wipe --transition-angle 30
fi

# 5. UI Refresh & Borders
# Refresh border colors directly from the generated skwd-wall cache
if [ -f "$CACHE_DIR/hyprland-colors.conf" ]; then
    CONF="$CACHE_DIR/hyprland-colors.conf"
    C1=$(sed -n 's/.*\$color1 = //p' "$CONF" 2>/dev/null | tr -d '[:space:]')
    C4=$(sed -n 's/.*\$color4 = //p' "$CONF" 2>/dev/null | tr -d '[:space:]')
    if [ -n "$C1" ] && [ -n "$C4" ]; then
        if hyprctl keyword general:col.active_border "$C4 $C1 45deg" 2>/dev/null; then
            log "Hyprland borders updated: $C4 $C1"
        else
            log_error "Failed to update hyprland borders"
        fi
    fi
else
    log_error "hyprland-colors.conf not found"
fi

# Reload Kitty colors via pkill (more reliable than kitten)
if pkill -USR1 kitty 2>/dev/null; then
    log "Sent USR1 to kitty"
else
    log "No kitty processes running or failed to signal"
fi

# SwayNC Reload (with timeout)
if timeout 2 swaync-client -rs 2>/dev/null; then
    log "SwayNC reloaded"
else
    log "SwayNC reload skipped (timeout or not running)"
fi

# 6. Notification
WALL_NAME=$(basename "$WALLPAPER")
if command -v notify-send &> /dev/null; then
    notify-send -i "$1" "Wallpaper Changed" "Applied: $(basename "$1")" 2>/dev/null || true
fi

echo "Sync successful: $WALL_NAME"
log "=== Wall-sync completed successfully ==="
