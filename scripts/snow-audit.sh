#!/bin/bash
########################################################################
##  SnowDots — Master Audit                              Version: v3.5.0  ##
########################################################################

HOSTNAME=$(hostname); GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# 1. Path Selection
[[ "$HOSTNAME" == "snowpi" ]] && { PRIMARY_REPO="$HOME/SnowPi-Dotfiles"; SECONDARY_REPO="$HOME/Dotfiles"; } || { PRIMARY_REPO="$HOME/Dotfiles"; SECONDARY_REPO="$HOME/SnowPi-Dotfiles"; }

echo -e "${BLUE}❄️  SnowDots Master Audit | Host: $HOSTNAME${NC}"
echo "---------------------------------------------------"

# 2. GIT CHANGE TRACKER
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

# 3. STORAGE MAP (Audit vs Sync Modes)
echo -e "\n${YELLOW}󱛟 Storage Map${NC}"
df -h -x tmpfs -x devtmpfs | grep -E '^/dev/|/mnt/' | awk '!seen[$2]++' | while read -r line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    PERC=$(echo "$line" | awk '{print $5}')
    USED=$(echo "$line" | awk '{print $3}')
    SIZE=$(echo "$line" | awk '{print $2}')
    VAL=${PERC%?}; [[ "$VAL" -gt 90 ]] && COLOR=$RED || COLOR=$GREEN

    # LOGIC: If run with --sync, only show drives > 70% or root
    if [[ "$1" == "--sync" ]]; then
        if [[ "$VAL" -gt 70 || "$MOUNT" == "/" ]]; then
            printf "  %-12s: ${COLOR}%s/%s (%s)${NC} @ %s\n" "$(basename "$MOUNT" | sed 's/^$/root/')" "$USED" "$SIZE" "$PERC" "$MOUNT"
        fi
    else
        # FULL AUDIT: Show all physical mounts
        if [[ "$MOUNT" == "/" || "$MOUNT" == "/home" || "$MOUNT" == /mnt/* || "$MOUNT" == "/boot" ]]; then
            printf "  %-12s: ${COLOR}%s/%s (%s)${NC} @ %s\n" "$(basename "$MOUNT" | sed 's/^$/root/')" "$USED" "$SIZE" "$PERC" "$MOUNT"
        fi
    fi
done

# 4. VISUAL ENGINE (Skip in Sync mode to save space)
if [[ "$1" != "--sync" ]]; then
    echo -e "\n${YELLOW}󰸉 Visual Engine Status${NC}"
    LIVE_WALL=$(awww query 2>/dev/null | grep -oP 'image: \K.*')
    echo -e "  Wallpaper   : ${GREEN}$(basename "${LIVE_WALL:-None}")${NC}"
    for p in awww-daemon skwd-daemon swaync; do
        pgrep -x "$p" > /dev/null && printf "  %-12s: ${GREEN}RUNNING${NC}\n" "$p" || printf "  %-12s: ${RED}STOPPED${NC}\n" "$p"
    done
fi

echo "---------------------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
