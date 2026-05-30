#!/bin/bash
########################################################################
##  SnowDots — Master Audit                              Version: v4.1  ##
########################################################################

HOSTNAME=$(hostname)
BOLD='\033[1m'; NC='\033[0m'

PRIMARY_REPO="$HOME/Dotfiles"

echo -e "${BOLD}❄️  SnowDots Master Audit | Host: $HOSTNAME${NC}"
echo "---------------------------------------------------"

# ── GIT SYNC STATUS ────────────────────────────
echo -e "${BOLD}☁️  Remote Sync Status${NC}"
if [ -d "$PRIMARY_REPO" ]; then
    cd "$PRIMARY_REPO" || exit

    if [[ "$HOSTNAME" == "snowpi" ]]; then
        CLOUD="origin"
        PEER="freezer"
    else
        CLOUD="gitlab"
        PEER="snowpi"
    fi

    # Cloud (GitLab)
    git fetch "$CLOUD" main 2>/dev/null
    CL_BEHIND=$(git rev-list HEAD.."$CLOUD"/main --count 2>/dev/null)
    CL_AHEAD=$(git rev-list "$CLOUD"/main..HEAD --count 2>/dev/null)
    if [ "$CL_AHEAD" -eq 0 ] && [ "$CL_BEHIND" -eq 0 ]; then
        printf "  %-12s: ${BOLD}Synced${NC}\n" "GitLab"
    else
        [ "$CL_AHEAD" -gt 0 ] && printf "  %-12s: ${BOLD}${CL_AHEAD} ahead${NC}\n" "GitLab"
        [ "$CL_BEHIND" -gt 0 ] && printf "  %-12s: ${BOLD}${CL_BEHIND} behind${NC}\n" "GitLab"
    fi

    # GitHub (Freezer only)
    if [[ "$HOSTNAME" == "freezer" ]] && git remote get-url github &>/dev/null; then
        git fetch github main 2>/dev/null
        GH_BEHIND=$(git rev-list HEAD..github/main --count 2>/dev/null || echo 0)
        GH_AHEAD=$(git rev-list github/main..HEAD --count 2>/dev/null || echo 0)
        if [ "$GH_AHEAD" -eq 0 ] && [ "$GH_BEHIND" -eq 0 ]; then
            printf "  %-12s: ${BOLD}Synced (sanitized)${NC}\n" "GitHub"
        elif [ "$GH_AHEAD" -gt 0 ] && [ "$GH_BEHIND" -gt 0 ]; then
            printf "  %-12s: ${BOLD}Diverged${NC} (+${GH_AHEAD}/-${GH_BEHIND})\n" "GitHub"
        elif [ "$GH_AHEAD" -gt 0 ]; then
            printf "  %-12s: ${BOLD}${GH_AHEAD} ahead${NC} (to publish)\n" "GitHub"
        else
            printf "  %-12s: ${BOLD}${GH_BEHIND} behind${NC}\n" "GitHub"
        fi
    fi

    # Peer
    if git remote get-url "$PEER" &>/dev/null; then
        printf "  %-12s: ${BOLD}Configured${NC}\n" "Peer"
    fi

    # Local file changes
    STATUS=$(git status --short)
    if [ -n "$STATUS" ]; then
        echo ""
        echo -e "  ${BOLD}Uncommitted Changes:${NC}"
        echo "$STATUS" | while read -r line; do
            MODE=$(echo "$line" | awk '{print $1}')
            FILE=$(echo "$line" | awk '{print $2}')
            SIZE=$([ -f "$FILE" ] && du -sh "$FILE" 2>/dev/null | awk '{print $1}' || echo "-")
            case $MODE in
                M| M) echo "    󰏫 Mod: $FILE ($SIZE)" ;;
                A|\?\?) echo "    󰐕 Add: $FILE ($SIZE)" ;;
                D| D) echo "    󰍶 Del: $FILE" ;;
            esac
        done
    fi

    # Local Backup (Freezer only)
    if [[ "$HOSTNAME" == "freezer" ]]; then
        BACKUP_DIR="/mnt/backups/System-Mirror/home-dots"
        if [ -d "$BACKUP_DIR" ]; then
            LAST_SYNC=$(stat -c %Y "$BACKUP_DIR" 2>/dev/null)
            NOW=$(date +%s)
            AGE_MIN=$(( (NOW - LAST_SYNC) / 60 ))
            echo ""
            printf "  %-12s: " "Local Backup"
            if [ "$AGE_MIN" -lt 60 ]; then
                echo -e "${BOLD}$AGE_MIN min ago${NC}"
            elif [ "$AGE_MIN" -lt 1440 ]; then
                echo -e "${BOLD}$((AGE_MIN / 60)) hr ago${NC}"
            else
                echo -e "${BOLD}$((AGE_MIN / 1440)) days ago${NC}"
            fi
        fi
    fi
fi

# ── SYSTEM STATUS ──────────────────────────────
echo -e "\n${BOLD}󰍹 System${NC}"
echo -e "  Uptime    : ${BOLD}$(uptime -p | sed 's/up //')${NC}"
TEMP=$(cat /sys/class/thermal/thermal_zone1/temp /sys/class/thermal/thermal_zone0/temp 2>/dev/null | head -1)
[ -n "$TEMP" ] && echo -e "  Temp      : ${BOLD}$((TEMP/1000))°C${NC}"

# ── NETWORK STATUS ─────────────────────────────
echo -e "\n${BOLD}󰇾 Network${NC}"
LOCAL_IP=$(ip -4 addr show | grep -oP 'inet \K192\.168\.[0-9]+\.[0-9]+' | head -1)
echo -e "  Local IP  : ${BOLD}${LOCAL_IP:-N/A}${NC}"
if command -v tailscale &>/dev/null; then
    TS_IP=$(tailscale ip -4 2>/dev/null || echo "offline")
    TS_PEERS=$(tailscale status 2>/dev/null | grep -cP '^\d+\.' || echo 0)
    echo -e "  Tailscale : ${BOLD}$TS_IP${NC} ($TS_PEERS peer(s))"
fi

# ── STORAGE MAP ────────────────────────────────
echo -e "\n${BOLD}󱛟 Storage${NC}"
df -h -x tmpfs -x devtmpfs | grep -E '^/dev/|/mnt/' | awk '!seen[$2]++' | while read -r line; do
    MOUNT=$(echo "$line" | awk '{print $6}')
    PERC=$(echo "$line" | awk '{print $5}')
    USED=$(echo "$line" | awk '{print $3}')
    SIZE=$(echo "$line" | awk '{print $2}')
    if [[ "$MOUNT" == "/" || "$MOUNT" == "/home" || "$MOUNT" == /mnt/* || "$MOUNT" == "/boot" ]]; then
        printf "  %-12s: %s/%s (%s) @ %s\n" "$(basename "$MOUNT" | sed 's/^$/root/')" "$USED" "$SIZE" "$PERC" "$MOUNT"
    fi
done

# ── SERVICES ───────────────────────────────────
echo -e "\n${BOLD}󰓦 Services${NC}"
if [[ "$HOSTNAME" == "freezer" ]]; then
    for s in Hyprland quickshell awww-daemon skwd-daemon; do
        pgrep -x "$s" &>/dev/null && printf "  %-12s: ${BOLD}RUNNING${NC}\n" "$s" || printf "  %-12s: STOPPED\n" "$s"
    done
elif [[ "$HOSTNAME" == "snowpi" ]]; then
    for s in pihole-FTL syncthing sshd; do
        pgrep -x "$s" &>/dev/null && printf "  %-12s: ${BOLD}RUNNING${NC}\n" "$s" || printf "  %-12s: STOPPED\n" "$s"
    done
fi
if command -v docker &>/dev/null; then
    DOCKER_COUNT=$(docker ps -q 2>/dev/null | wc -l)
    DOCKER_NAMES=$(docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ' ')
    printf "  %-12s: ${BOLD}%d container(s)${NC} %s\n" "Docker" "$DOCKER_COUNT" "$DOCKER_NAMES"
fi

echo "---------------------------------------------------"
echo -e "${BOLD}Audit Complete.${NC}"
