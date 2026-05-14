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

# 4. Apply the Image using awww
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
    # Reload hyprland to ensure all color changes take effect
    hyprctl reload 2>/dev/null || true
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

# Fuzzel Colors Update
FUZZEL_GEN="$HOME/.cache/skwd-wall/fuzzel-colors.ini"
FUZZEL_CFG="$HOME/.config/fuzzel/fuzzel.ini"
if [ -f "$FUZZEL_GEN" ]; then
    BG=$(grep "^background=" "$FUZZEL_GEN" | cut -d= -f2)
    TEXT=$(grep "^text=" "$FUZZEL_GEN" | cut -d= -f2)
    MATCH=$(grep "^match=" "$FUZZEL_GEN" | cut -d= -f2)
    SEL=$(grep "^selection=" "$FUZZEL_GEN" | cut -d= -f2)
    BORDER=$(grep "^border=" "$FUZZEL_GEN" | cut -d= -f2)
    
    if [ -n "$BG" ]; then
        # Colors from matugen come as hex (e.g. 161217dd), add alpha suffix for fuzzel format
        sed -i "s/^background=.*/background=${BG}/" "$FUZZEL_CFG"
        sed -i "s/^text=.*/text=${TEXT}/" "$FUZZEL_CFG"
        sed -i "s/^prompt=.*/prompt=${MATCH}/" "$FUZZEL_CFG"
        sed -i "s/^match=.*/match=${MATCH}/" "$FUZZEL_CFG"
        sed -i "s/^selection=.*/selection=${SEL}/" "$FUZZEL_CFG"
        sed -i "s/^border=.*/border=${BORDER}/" "$FUZZEL_CFG"
        # Set other colors to match theme
        sed -i "s/^placeholder=.*/placeholder=998d96ff/" "$FUZZEL_CFG"
        sed -i "s/^input=.*/input=${TEXT}/" "$FUZZEL_CFG"
        sed -i "s/^selection-text=.*/selection-text=e9e0e7ff/" "$FUZZEL_CFG"
        sed -i "s/^selection-match=.*/selection-match=a0d0c8ff/" "$FUZZEL_CFG"
        sed -i "s/^counter=.*/counter=998d96ff/" "$FUZZEL_CFG"
        log "Fuzzel colors updated"
    fi
fi

# Update Cursor Colors (matugen dynamic)
if [ -f "$HOME/Dotfiles/scripts/cursor-colors.sh" ]; then
    "$HOME/Dotfiles/scripts/cursor-colors.sh" >> "$LOG_FILE" 2>&1 || log_error "Cursor colors failed"
    log "Cursor colors updated"
fi

# Update Btop Theme (matugen dynamic)
BTOP_TEMPLATE="$HOME/Dotfiles/matugen/templates/btop.theme"
BTOP_THEME="$HOME/.config/btop/themes/matugen.theme"
if [ -f "$BTOP_TEMPLATE" ] && [ -f "$FUZZEL_GEN" ]; then
    # Extract colors from fuzzel-gen and create btop theme
    PRIMARY=$(grep "^border=" "$FUZZEL_GEN" | cut -d= -f2 | cut -c1-6)
    SECONDARY=$(grep "^match=" "$FUZZEL_GEN" | cut -d= -f2 | cut -c1-6)
    TERTIARY=$(grep "^selection=" "$FUZZEL_GEN" | cut -d= -f2 | cut -c1-6)
    BG=$(grep "^background=" "$FUZZEL_GEN" | cut -d= -f2 | cut -c1-6)
    TEXT=$(grep "^text=" "$FUZZEL_GEN" | cut -d= -f2 | cut -c1-6)

    [ -z "$PRIMARY" ] && PRIMARY="e4b7f3"
    [ -z "$SECONDARY" ] && SECONDARY="a0d0c8"
    [ -z "$TERTIARY" ] && TERTIARY="f8d8ff"
    [ -z "$BG" ] && BG="161217"
    [ -z "$TEXT" ] && TEXT="e9e0e7"

    sed -e "s/{{colors.surface.default.hex}}/#${BG}/g" \
        -e "s/{{colors.on_surface.default.hex}}/#${TEXT}/g" \
        -e "s/{{colors.on_surface_variant.default.hex}}/#${PRIMARY}/g" \
        -e "s/{{colors.surface_container_high.default.hex}}/#232325/g" \
        -e "s/{{colors.primary.default.hex}}/#${PRIMARY}/g" \
        -e "s/{{colors.secondary.default.hex}}/#${SECONDARY}/g" \
        -e "s/{{colors.tertiary.default.hex}}/#${TERTIARY}/g" \
        -e "s/{{colors.outline.default.hex}}/#666666/g" \
        -e "s/{{colors.surface_container_default.hex}}/#2a2a2a/g" \
        "$BTOP_TEMPLATE" > "$BTOP_THEME" 2>/dev/null || true
    log "Btop theme updated"
fi

# 6. Notification - show wallpaper name and thumbnail
WALL_NAME=$(basename "$WALLPAPER")
if command -v notify-send &> /dev/null; then
    notify-send -i "$WALLPAPER" "Wallpaper Changed" "Applied: $WALL_NAME" 2>/dev/null || true
fi

# 7. Update Fastfetch Colors (dynamic using hex codes from cache)
KITTY_CACHE="$HOME/.cache/skwd-wall/colors-kitty.conf"
FF_CONFIG="$HOME/.config/fastfetch/config.jsonc"

if [ -f "$KITTY_CACHE" ]; then
    C1=$(grep -E "^color1\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C2=$(grep -E "^color2\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C4=$(grep -E "^color4\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C9=$(grep -E "^color9\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C8=$(grep -E "^color8\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    
    [ -z "$C1" ] && C1="#b7d084"
    [ -z "$C2" ] && C2="#a0d0c8"
    [ -z "$C4" ] && C4="#3a4d10"
    [ -z "$C9" ] && C9="#d3ec9e"
    [ -z "$C8" ] && C8="#909284"
    
    cat > "$FF_CONFIG" << EOF
{
  "\$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "padding": { "top": 2 },
    "color": { "1": "$C1", "2": "$C4" }
  },
  "display": { "separator": " ➜  " },
  "modules": [
    "break",
    { "type": "title", "format": "{user-name-colored}@{host-name-colored}" },
    { "type": "custom", "format": " \u001b[90m─────── Software ───────" },
    { "type": "os", "key": "󰣇", "keyColor": "$C1" },
    { "type": "command", "key": "󰄉", "keyColor": "$C9", "text": "birth_install=\$(stat -c %W / | tr -d '-'); now=\$(date +%s); echo \$(( (now - birth_install) / 86400 )) days", "shell": "/bin/sh" },
    { "type": "localip", "key": "󰩟", "keyColor": "$C2", "compact": true },
    { "type": "command", "key": "󱖨", "keyColor": "$C4", "text": "echo \$(docker ps --format '{{.Names}}' | wc -l) containers / \$(systemctl list-units --type=service --state=running | grep '.service' | wc -l) services", "shell": "/bin/sh" },
    { "type": "custom", "format": " \u001b[90m─────── Hardware ───────" },
    { "type": "cpu", "key": "󰻠", "keyColor": "$C1" },
    { "type": "gpu", "key": "󰍛", "keyColor": "$C9" },
    { "type": "disk", "key": "Root", "keyColor": "$C9", "folders": ["/"] },
    { "type": "disk", "key": "Home", "keyColor": "$C4", "folders": ["/home"] },
    { "type": "memory", "key": "󰑭", "keyColor": "$C8" },
    { "type": "uptime", "key": "󰅐", "keyColor": "$C2" },
    { "type": "command", "key": "󰔄", "keyColor": "$C9", "text": "if [ -f /sys/class/thermal/thermal_zone0/temp ]; then echo \"\$((\$(cat /sys/class/thermal/thermal_zone0/temp) / 1000))°C\"; else echo \"N/A\"; fi", "shell": "/bin/sh" },
    { "type": "custom", "format": " \u001b[90m────────────────────────────────────" },
    "break",
    { "type": "colors", "symbol": "circle" },
    { "type": "wallpaper", "key": "󰌨" }
  ]
}
EOF
    log "Fastfetch colors updated: $C1 $C2 $C4 $C9 $C8"
fi

# Run fastfetch to update current terminal (text updates, icons/logo need new terminal)
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    clear 2>/dev/null || true
    fastfetch --pipe false 2>/dev/null || true
fi

echo "Sync successful: $WALL_NAME"
log "=== Wall-sync completed successfully ==="
