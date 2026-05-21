#!/usr/bin/env bash

CACHE_DIR="${HOME}/.cache/skwd-wall"
HYPR_CACHE="${CACHE_DIR}/hyprland-colors.conf"
KITTY_CACHE="${CACHE_DIR}/colors-kitty.conf"
FUZZEL_CACHE="${CACHE_DIR}/fuzzel-colors.ini"
WALLPAPER_CACHE="${CACHE_DIR}/last-wallpaper.json"

strip_alpha() {
    echo "${1:0:8}"
}

print_block() {
    local hex="$1"
    [[ -z "$hex" || ${#hex} -lt 6 ]] && return
    hex="${hex//#/}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf "\033[48;2;%d;%d;%dm■\033[0m" "$r" "$g" "$b"
}

print_color() {
    local hex="$1"
    local name="$2"
    [[ -z "$hex" || ${#hex} -lt 6 ]] && return
    hex="${hex//#/}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf "\033[48;2;%d;%d;%dm  \033[0m" "$r" "$g" "$b"
    printf " %-10s #%s" "$name" "$hex"
}

echo "=============================================="
echo "  MATUGEN COLOR STATUS"
echo "=============================================="
echo ""

if [[ -f "$WALLPAPER_CACHE" ]]; then
    WALLPAPER=$(cat "$WALLPAPER_CACHE" | jq -r '.path // .path')
    echo "Wallpaper: ${WALLPAPER}"
    echo ""
fi

echo "--- Hyprland Colors ---"
if [[ -f "$HYPR_CACHE" ]]; then
    COLOR1=$(grep '^\$color1' "$HYPR_CACHE" | sed 's/.*rgba(\([^)]*\)).*/\1/' | cut -c1-8)
    COLOR4=$(grep '^\$color4' "$HYPR_CACHE" | sed 's/.*rgba(\([^)]*\)).*/\1/' | cut -c1-8)
    INACTIVE=$(grep '^\$inactive' "$HYPR_CACHE" | sed 's/.*rgba(\([^)]*\)).*/\1/' | cut -c1-8)
    echo -n "Colors: "
    print_block "$COLOR1"
    print_block "$COLOR4"
    print_block "$INACTIVE"
    echo ""
    echo "  Primary:  #${COLOR1}"
    echo "  Accent:   #${COLOR4}"
    echo "  Inactive: #${INACTIVE:0:6}"
else
    echo "  Not found: $HYPR_CACHE"
fi
echo ""

echo "--- Kitty Colors ---"
if [[ -f "$KITTY_CACHE" ]]; then
    FG=$(grep -E "^foreground" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    BG=$(grep -E "^background" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    CUR=$(grep -E "^cursor" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C0=$(grep -E "^color0\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C1=$(grep -E "^color1\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C2=$(grep -E "^color2\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C3=$(grep -E "^color3\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C4=$(grep -E "^color4\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C5=$(grep -E "^color5\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C6=$(grep -E "^color6\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C7=$(grep -E "^color7\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C8=$(grep -E "^color8\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    C9=$(grep -E "^color9\s" "$KITTY_CACHE" | head -1 | awk '{print $2}')
    
    echo "FG: $FG  BG: $BG  CUR: $CUR"
    echo -n "Palette: "
    print_block "$C0"; print_block "$C1"; print_block "$C2"; print_block "$C3"
    print_block "$C4"; print_block "$C5"; print_block "$C6"; print_block "$C7"
    echo ""
    echo "        "
    print_block "$C8"; print_block "$C9"
    echo ""
else
    echo "  Not found: $KITTY_CACHE"
fi
echo ""

echo "--- Fuzzel Colors ---"
if [[ -f "$FUZZEL_CACHE" ]]; then
    BG=$(grep "^background=" "$FUZZEL_CACHE" | cut -d= -f2 | cut -c1-6)
    TEXT=$(grep "^text=" "$FUZZEL_CACHE" | cut -d= -f2 | cut -c1-6)
    MATCH=$(grep "^match=" "$FUZZEL_CACHE" | cut -d= -f2 | cut -c1-6)
    BORDER=$(grep "^border=" "$FUZZEL_CACHE" | cut -d= -f2 | cut -c1-6)
    
    echo -n "Colors: "
    print_block "$BG"; print_block "$TEXT"
    print_block "$MATCH"; print_block "$BORDER"
    echo ""
    echo "  BG:      #$BG"
    echo "  Text:    #$TEXT"
    echo "  Match:   #$MATCH"
    echo "  Border:  #$BORDER"
else
    echo "  Not found: $FUZZEL_CACHE"
fi
echo ""

echo "--- Live System Check ---"
echo ""

HYPR_ACTIVE=$(hyprctl getoption decoration:rounding -j 2>/dev/null | jq -r '.int')
if [[ -n "$HYPR_ACTIVE" ]]; then
    echo "[✓] Hyprland is running"
    if source "$HYPR_CACHE" 2>/dev/null; then
        echo "    Current config colors:"
        echo "    \$color1 = ${color1}"
        echo "    \$color4 = ${color4}"
    fi
else
    echo "[✗] Hyprland not running"
fi
echo ""

if pgrep -x "kitty" >/dev/null; then
    echo "[✓] Kitty is running"
    KITTY_CONF="${HOME}/.config/kitty/current-theme.conf"
    if [[ -f "$KITTY_CONF" ]]; then
        FG=$(grep "^foreground" "$KITTY_CONF" 2>/dev/null | awk '{print $2}')
        echo "    Current theme foreground: $FG"
    fi
else
    echo "[✗] Kitty not running"
fi

echo ""
echo "=============================================="