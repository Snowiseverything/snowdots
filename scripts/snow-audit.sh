#!/bin/bash
########################################################################
##  SnowDots — Master Audit                              Version: v4.1  ##
########################################################################

HOSTNAME=$(hostname)
BOLD='\033[1m'; NC='\033[0m'

PRIMARY_REPO="$HOME/Dotfiles"

echo -e "${BOLD}❄️  Audit | Host: $HOSTNAME${NC}"
echo "---------------------------------------------------"

# ── GIT SYNC STATUS ────────────────────────────
check_repo() {
    local REPO="$1"
    local LABEL="$2"
    if [ ! -d "$REPO" ]; then return; fi
    cd "$REPO" || return

    if [[ "$HOSTNAME" == "snowpi" ]] && [[ "$REPO" == "$HOME/Dotfiles" ]]; then
        CLOUD="origin"
        PEER="freezer"
    elif [[ "$HOSTNAME" == "snowpi" ]] && [[ "$REPO" == "$HOME/Freezer-Dotfiles" ]]; then
        CLOUD="origin"
        PEER=""
    else
        CLOUD="gitlab"
        PEER="snowpi"
    fi

    if [ "$LABEL" != "main" ]; then echo ""; fi
    echo -e "  ${BOLD}$LABEL${NC} ($(basename "$REPO"))"

    git fetch "$CLOUD" main 2>/dev/null
    CL_BEHIND=$(git rev-list HEAD.."$CLOUD"/main --count 2>/dev/null)
    CL_AHEAD=$(git rev-list "$CLOUD"/main..HEAD --count 2>/dev/null || echo 0)

    if [ "$CL_AHEAD" -eq 0 ] && [ "$CL_BEHIND" -eq 0 ]; then
        echo "    GitLab: Synced"
    else
        [ "$CL_AHEAD" -gt 0 ] && echo "    GitLab: ${CL_AHEAD} ahead"
        [ "$CL_BEHIND" -gt 0 ] && echo "    GitLab: ${CL_BEHIND} behind"
    fi

    # GitHub (Freezer main repo only)
    if [[ "$HOSTNAME" == "freezer" ]] && [[ "$REPO" == "$HOME/Dotfiles" ]] && git remote get-url github &>/dev/null; then
        git fetch github main 2>/dev/null
        GH_BEHIND=$(git rev-list HEAD..github/main --count 2>/dev/null || echo 0)
        GH_AHEAD=$(git rev-list github/main..HEAD --count 2>/dev/null || echo 0)
        if [ "$GH_AHEAD" -eq 0 ] && [ "$GH_BEHIND" -eq 0 ]; then
            echo "    GitHub: Synced (sanitized)"
        elif [ "$GH_AHEAD" -gt 0 ] && [ "$GH_BEHIND" -gt 0 ]; then
            echo "    GitHub: Diverged (+${GH_AHEAD}/-${GH_BEHIND})"
        elif [ "$GH_AHEAD" -gt 0 ]; then
            echo "    GitHub: ${GH_AHEAD} ahead (to publish)"
        else
            echo "    GitHub: ${GH_BEHIND} behind"
        fi
    fi

    if [ -n "$PEER" ] && git remote get-url "$PEER" &>/dev/null; then
        echo "    Peer: Configured"
    fi

    STATUS=$(git status --short)
    if [ -n "$STATUS" ]; then
        echo "    Uncommitted:"
        echo "$STATUS" | while read -r line; do
            MODE=$(echo "$line" | awk '{print $1}')
            FILE=$(echo "$line" | awk '{print $2}')
            case $MODE in
                M| M) echo "      󰏫 $FILE" ;;
                A|\?\?) echo "      󰐕 $FILE" ;;
                D| D) echo "      󰍶 $FILE" ;;
            esac
        done
    fi
}

echo -e "${BOLD}☁️  Git Status${NC}"
check_repo "$HOME/Dotfiles" "main"
if [[ "$HOSTNAME" == "snowpi" ]]; then
    check_repo "$HOME/Freezer-Dotfiles" "peer"
fi

# Local Backup (Freezer only)
if [[ "$HOSTNAME" == "freezer" ]]; then
    BACKUP_DIR="/mnt/backups/System-Mirror/home-dots"
    if [ -d "$BACKUP_DIR" ]; then
        LAST_SYNC=$(stat -c %Y "$BACKUP_DIR" 2>/dev/null)
        NOW=$(date +%s)
        AGE_MIN=$(( (NOW - LAST_SYNC) / 60 ))
        echo ""
        printf "  %-12s: " "Backup"
        if [ "$AGE_MIN" -lt 60 ]; then echo -e "${BOLD}$AGE_MIN min ago${NC}"
        elif [ "$AGE_MIN" -lt 1440 ]; then echo -e "${BOLD}$((AGE_MIN / 60)) hr ago${NC}"
        else echo -e "${BOLD}$((AGE_MIN / 1440)) days ago${NC}"
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
