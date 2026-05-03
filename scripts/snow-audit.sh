#!/bin/bash

# Colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}❄️ SnowDots System Audit${NC}"
echo "---------------------------------------"

# 1. SCRIPTS CHECK
echo -e "${YELLOW}󱆃 Checking Core Scripts...${NC}"
scripts=("wall-sync.sh" "wall-reset.sh" "rename-wallpapers.sh" "dotsync" "audit-dots.sh")
for s in "${scripts[@]}"; do
    if [ -f "$HOME/Dotfiles/scripts/$s" ]; then
        echo -e "  [${GREEN}OK${NC}] $s"
    else
        echo -e "  [${RED}MISSING${NC}] $s"
    fi
done

# 2. DAEMON CHECK
echo -e "\n${YELLOW}󱚧 Checking Daemons...${NC}"
daemons=("awww-daemon" "skwd-daemon" "matugen" "swaync")
for d in "${daemons[@]}"; do
    if pgrep -x "$d" > /dev/null; then
        echo -e "  [${GREEN}RUNNING${NC}] $d"
    else
        echo -e "  [${RED}STOPPED${NC}] $d"
    fi
done

# 3. WALLPAPER STATE
echo -e "\n${YELLOW}󰸉 Wallpaper Persistence...${NC}"
LAST_WALL_FILE="$HOME/.cache/skwd-wall/last_applied_wall.txt"
if [ -f "$LAST_WALL_FILE" ]; then
    WALL_PATH=$(cat "$LAST_WALL_FILE")
    echo -e "  Current State: ${GREEN}$(basename "$WALL_PATH")${NC}"
else
    echo -e "  ${RED}⚠️ No persistence file found.${NC}"
fi

# 4. SYSTEM INFO (CachyOS Specific)
echo -e "\n${YELLOW}󰣇 System Info...${NC}"
echo -e "  Kernel: $(uname -r)"
echo -e "  Brave:  $(brave --version 2>/dev/null || echo "Not found")"

echo "---------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
