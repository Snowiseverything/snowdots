#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}❄️ SnowDots Advanced System Audit${NC}"
echo "---------------------------------------"

# 1. LIVE WALLPAPER STATUS
echo -e "${YELLOW}󰸉 Wallpaper Status${NC}"
LIVE_WALL=$(awww query | grep -oP 'image: \K.*')
PERSIST_WALL=$(cat "$HOME/.cache/skwd-wall/last_applied_wall.txt" 2>/dev/null)

if [ "$LIVE_WALL" == "$PERSIST_WALL" ]; then
    echo -e "  Active: ${GREEN}$(basename "$LIVE_WALL")${NC} (Synced)"
else
    echo -e "  Active: ${RED}$(basename "$LIVE_WALL")${NC}"
    echo -e "  Saved:  ${YELLOW}$(basename "$PERSIST_WALL")${NC}"
fi

# 2. VERSION TRACKING
echo -e "\n${YELLOW}󰏖 Version Control${NC}"
check_version() {
    local name=$1
    local cmd=$2
    version=$($cmd 2>/dev/null | head -n 1)
    if [ -n "$version" ]; then
        echo -e "  %-12s : ${GREEN}%s${NC}" "$name" "$version"
    else
        echo -e "  %-12s : ${RED}Not Installed${NC}" "$name"
    fi
}

check_version "Hyprland" "hyprctl version | head -n 1"
check_version "skwd" "skwd --version"
check_version "Matugen" "matugen --version"
check_version "Brave" "brave --version"

# 3. CONFIG VALIDATION
echo -e "\n${YELLOW}󰒓 Config Integrity${NC}"
# Hyprland has a built-in check in newer versions; otherwise we check file existence
if hyprctl configcheck >/dev/null 2>&1; then
    echo -e "  Hyprland    : ${GREEN}Valid${NC}"
else
    [ -f "$HOME/.config/hypr/hyprland.conf" ] && echo -e "  Hyprland    : ${GREEN}Exists (Manual Check Req)${NC}" || echo -e "  Hyprland    : ${RED}Missing${NC}"
fi

# Check skwd config
[ -f "$HOME/.config/skwd/skwd.toml" ] && echo -e "  skwd        : ${GREEN}Config Present${NC}" || echo -e "  skwd        : ${RED}Config Missing${NC}"

# 4. DAEMON & TOOL HEALTH
echo -e "\n${YELLOW}󱚧 Process Health${NC}"
check_proc() {
    if pgrep -x "$1" > /dev/null; then
        echo -e "  %-12s : ${GREEN}RUNNING${NC}" "$1"
    elif which "$1" > /dev/null 2>&1; then
        echo -e "  %-12s : ${YELLOW}AVAILABLE (CLI)${NC}" "$1"
    else
        echo -e "  %-12s : ${RED}MISSING${NC}" "$1"
    fi
}

check_proc "awww-daemon"
check_proc "skwd-daemon"
check_proc "matugen"
check_proc "swaync"

echo "---------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
