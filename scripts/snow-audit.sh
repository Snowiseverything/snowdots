#!/bin/bash
########################################################################
##  SnowDots — Master Audit                              Version: v3.1.5  ##
########################################################################

HOSTNAME=$(hostname); GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# 1. Path Selection
[[ "$HOSTNAME" == "snowpi" ]] && { PRIMARY_REPO="$HOME/SnowPi-Dotfiles"; SECONDARY_REPO="$HOME/Dotfiles"; } || { PRIMARY_REPO="$HOME/Dotfiles"; SECONDARY_REPO="$HOME/SnowPi-Dotfiles"; }

echo -e "${BLUE}❄️  SnowDots Master Audit | Host: $HOSTNAME${NC}"
echo "---------------------------------------------------"

# 2. GIT CHANGE TRACKER (Added/Removed/Modified)
echo -e "${YELLOW}☁️  GitLab Sync Status & File Changes${NC}"
for REPO in "$PRIMARY_REPO" "$SECONDARY_REPO"; do
    if [ -d "$REPO" ]; then
        cd "$REPO" || exit
        STATUS=$(git status --short)
        if [ -z "$STATUS" ]; then
            printf "  %-12s: ${GREEN}Clean (Synced)${NC}\n" "$(basename "$REPO")"
        else
            printf "  %-12s: ${RED}Pending Changes:${NC}\n" "$(basename "$REPO")"
            git status --short | while read -r line; do
                MODE=$(echo "$line" | awk '{print $1}')
                FILE=$(echo "$line" | awk '{print $2}')
                # Get size of new/modified files
                SIZE=$([ -f "$FILE" ] && du -sh "$FILE" | awk '{print $1}' || echo "N/A")
                case $MODE in
                    M) echo -e "    ${YELLOW}󰏫 Mod:${NC} $FILE ($SIZE)" ;;
                    A|??) echo -e "    ${GREEN}󰐕 Add:${NC} $FILE ($SIZE)" ;;
                    D) echo -e "    ${RED}󰍶 Del:${NC} $FILE" ;;
                esac
            done
        fi
    fi
done

# 3. COMPREHENSIVE STORAGE MAP
echo -e "\n${YELLOW}󱛟 Storage Map (All Mounts)${NC}"
df -h | grep -E '^/dev/|/mnt/' | grep -v 'loop' | while read -r line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    PERC=$(echo "$line" | awk '{print $5}')
    USED=$(echo "$line" | awk '{print $3}')
    SIZE=$(echo "$line" | awk '{print $2}')
    
    VAL=${PERC%?}; [[ "$VAL" -gt 90 ]] && COLOR=$RED || [[ "$VAL" -gt 70 ]] && COLOR=$YELLOW || COLOR=$GREEN
    printf "  %-12s: ${COLOR}%s/%s (%s)${NC} @ %s\n" "$(basename "$MOUNT" | sed 's/^$/root/')" "$USED" "$SIZE" "$PERC" "$MOUNT"
done

# 4. ENGINE STATUS
if [[ "$HOSTNAME" != "snowpi" ]]; then
    echo -e "\n${YELLOW}󰸉 Visual Engine Status${NC}"
    LIVE_WALL=$(awww query 2>/dev/null | grep -oP 'image: \K.*')
    echo -e "  Wallpaper   : ${GREEN}$(basename "${LIVE_WALL:-None}")${NC}"
    for p in awww-daemon skwd-daemon swaync; do
        pgrep -x "$p" > /dev/null && printf "  %-12s: ${GREEN}RUNNING${NC}\n" "$p" || printf "  %-12s: ${RED}STOPPED${NC}\n" "$p"
    done
else
    echo -e "\n${YELLOW}󱚧 IoT & Docker Containers${NC}"
    docker ps --format '{{.Names}}' | grep -E "homeassistant|pihole" | while read -r name; do
        echo -e "  $name : ${GREEN}RUNNING${NC}"
    done
fi

# 5. INTEGRITY
echo -e "\n${YELLOW}󰏖 Symlink Integrity${NC}"
BROKEN=$(find ~/.config -maxdepth 2 -xtype l ! -path "*discord*" 2>/dev/null)
[ -z "$BROKEN" ] && echo -e "  Symlinks    : ${GREEN}Valid${NC}" || echo -e "  Symlinks    : ${RED}Broken Found!${NC}"

echo "---------------------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
