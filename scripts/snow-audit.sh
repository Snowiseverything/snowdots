#!/bin/bash
########################################################################
##  SnowDots — Master Audit                              Version: v3.0.0  ##
##  Last Edited: 2026-05-04                                            ##
########################################################################

HOSTNAME=$(hostname)
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Path Selection
if [[ "$HOSTNAME" == "snowpi" ]]; then
    PRIMARY_REPO="$HOME/SnowPi-Dotfiles"; SECONDARY_REPO="$HOME/Dotfiles"
else
    PRIMARY_REPO="$HOME/Dotfiles"; SECONDARY_REPO="$HOME/SnowPi-Dotfiles"
fi

echo -e "${BLUE}❄️  SnowDots Master Audit | Host: $HOSTNAME${NC}"
echo "---------------------------------------------------"

# 2. SYSTEM LOAD & UPTIME
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(cut -d' ' -f1-3 /proc/loadavg)
echo -e "${YELLOW}󰵠 System Vitals${NC}"
echo -e "  Uptime      : ${GREEN}$UPTIME${NC}"
echo -e "  Load Avg    : ${GREEN}$LOAD${NC}"

# 3. GIT & REPO STATUS
echo -e "\n${YELLOW}☁️  GitLab Sync Status [$PRIMARY_REPO]${NC}"
if [ -d "$PRIMARY_REPO" ]; then
    cd "$PRIMARY_REPO" || exit
    git fetch gitlab >/dev/null 2>&1
    BEHIND=$(git rev-list HEAD..gitlab/main --count 2>/dev/null || echo 0)
    AHEAD=$(git rev-list gitlab/main..HEAD --count 2>/dev/null || echo 0)
    [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ] && echo -e "  GitLab      : ${GREEN}Synced${NC}" || echo -e "  GitLab      : ${RED}Out of Sync (A:$AHEAD B:$BEHIND)${NC}"
fi

for REPO in "$PRIMARY_REPO" "$SECONDARY_REPO"; do
    if [ -d "$REPO" ]; then
        cd "$REPO" || exit
        [ -z "$(git status --short)" ] && printf "  %-12s: ${GREEN}Clean${NC}\n" "$(basename "$REPO")" || printf "  %-12s: ${RED}Modified${NC}\n" "$(basename "$REPO")"
    fi
done

# 4. STORAGE SCAN (The "Deep Scan")
echo -e "\n${YELLOW}󱛟 Storage Map${NC}"
# Scan for Root, Home, and any /mnt partitions
df -h | grep -E '^/dev/|/mnt/' | grep -v 'loop' | while read -r line; do
    FILESYSTEM=$(echo "$line" | awk '{print $1}')
    SIZE=$(echo "$line" | awk '{print $2}')
    USED=$(echo "$line" | awk '{print $3}')
    PERC=$(echo "$line" | awk '{print $5}')
    MOUNT=$(echo "$line" | awk '{print $6}')
    
    # Color code based on usage percentage
    VAL=${PERC%?}
    if [ "$VAL" -gt 90 ]; then COLOR=$RED; elif [ "$VAL" -gt 70 ]; then COLOR=$YELLOW; else COLOR=$GREEN; fi
    
    printf "  %-12s: ${COLOR}%-5s / %-5s (%s)${NC} @ %s\n" "$(basename "$MOUNT" | sed 's/^$/root/')" "$USED" "$SIZE" "$PERC" "$MOUNT"
done

# 5. HOST-SPECIFIC ENGINE CHECKS
if [[ "$HOSTNAME" != "snowpi" ]]; then
    echo -e "\n${YELLOW}󰸉 Visual Engine Status${NC}"
    LIVE_WALL=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | tr -d '[:space:]')
    echo -e "  Wallpaper   : ${GREEN}$(basename "${LIVE_WALL:-None}")${NC}"

    echo -e "\n${YELLOW}󱚧 Desktop Daemons${NC}"
    for p in awww-daemon skwd-daemon swaync; do
        pgrep -x "$p" > /dev/null && printf "  %-12s: ${GREEN}ON${NC}\n" "$p" || printf "  %-12s: ${RED}OFF${NC}\n" "$p"
    done
else
    echo -e "\n${YELLOW}󱚧 IoT & Docker Services${NC}"
    if systemctl is-active --quiet docker; then
        echo -e "  Docker      : ${GREEN}Active${NC}"
        # Check specific containers
        for c in homeassistant pihole; do
            docker ps --format '{{.Names}}' | grep -q "$c" && printf "  %-12s: ${GREEN}RUNNING${NC}\n" "$c" || printf "  %-12s: ${RED}DOWN${NC}\n" "$c"
        done
    else
        echo -e "  Docker      : ${RED}OFFLINE${NC}"
    fi
fi

# 6. INTEGRITY
echo -e "\n${YELLOW}󰏖 Integrity${NC}"
BROKEN=$(find ~/.config -maxdepth 2 -xtype l ! -path "*discord*" 2>/dev/null)
[ -z "$BROKEN" ] && echo -e "  Symlinks    : ${GREEN}Valid${NC}" || echo -e "  Symlinks    : ${RED}Broken Found!${NC}"

echo "---------------------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
