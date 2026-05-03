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
LIVE_WALL=$(awww query | grep -oP 'image: \K.*' | tr -d '[:space:]')
PERSIST_WALL=$(cat "$HOME/.cache/skwd-wall/last_applied_wall.txt" 2>/dev/null)

if [ -n "$LIVE_WALL" ] && [ "$LIVE_WALL" == "$PERSIST_WALL" ]; then
    echo -e "  Active: ${GREEN}$(basename "$LIVE_WALL")${NC} (Synced)"
else
    [ -n "$LIVE_WALL" ] && echo -e "  Active: ${RED}$(basename "$LIVE_WALL")${NC}"
    [ -n "$PERSIST_WALL" ] && echo -e "  Saved:  ${YELLOW}$(basename "$PERSIST_WALL")${NC}"
fi

# 2. VERSION TRACKING
echo -e "\n${YELLOW}󰏖 Version Control${NC}"
check_version() {
    local name=$1
    local cmd=$2
    # Use printf for alignment instead of echo
    raw_version=$(eval "$cmd" 2>/dev/null | head -n 1 | grep -oP '\d+\.\d+\.\d+' || eval "$cmd" 2>/dev/null | head -n 1 | awk '{print $NF}')
    
    if [ -n "$raw_version" ]; then
        printf "  %-12s : ${GREEN}%s${NC}\n" "$name" "$raw_version"
    else
        printf "  %-12s : ${RED}Not Installed${NC}\n" "$name"
    fi
}

check_version "Hyprland" "hyprctl version | grep -i 'Tag'"
check_version "skwd" "skwd status 2>/dev/null | jq -r '.version'"
check_version "Matugen" "matugen --version"
check_version "Brave" "brave --version"

# 3. CONFIG VALIDATION
echo -e "\n${YELLOW}󰒓 Config Integrity${NC}"
if hyprctl configcheck >/dev/null 2>&1; then
    echo -e "  Hyprland    : ${GREEN}Valid${NC}"
else
    [ -f "$HOME/.config/hypr/hyprland.conf" ] && echo -e "  Hyprland    : ${GREEN}Exists${NC}" || echo -e "  Hyprland    : ${RED}Missing${NC}"
fi

# Smarter skwd config check
if [ -d "$HOME/.config/skwd" ] && ls "$HOME/.config/skwd/"* >/dev/null 2>&1; then
    echo -e "  skwd        : ${GREEN}Config Present${NC}"
else
    echo -e "  skwd        : ${RED}Config Missing${NC}"
fi

# 4. PROCESS HEALTH
echo -e "\n${YELLOW}󱚧 Process Health${NC}"
check_proc() {
    local name=$1
    if pgrep -x "$name" > /dev/null; then
        printf "  %-12s : ${GREEN}RUNNING${NC}\n" "$name"
    elif which "$name" > /dev/null 2>&1; then
        printf "  %-12s : ${YELLOW}AVAILABLE (CLI)${NC}\n" "$name"
    else
        printf "  %-12s : ${RED}MISSING${NC}\n" "$name"
    fi
}

check_proc "awww-daemon"
check_proc "skwd-daemon"
check_proc "matugen"
check_proc "swaync"

echo "---------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
