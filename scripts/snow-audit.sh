#!/bin/bash
########################################################################
##  SnowDots — Master Audit                              Version: v2.1.0  ##
##  Last Edited: 2026-05-04                                            ##
########################################################################

HOSTNAME=$(hostname)
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 1. Path Selection based on Hostname
if [[ "$HOSTNAME" == "snowpi" ]]; then
    PRIMARY_REPO="$HOME/SnowPi-Dotfiles"
    SECONDARY_REPO="$HOME/Dotfiles"
else
    PRIMARY_REPO="$HOME/Dotfiles"
    SECONDARY_REPO="$HOME/SnowPi-Dotfiles"
fi

echo -e "${BLUE}❄️  SnowDots Master Audit | Host: $HOSTNAME${NC}"
echo "---------------------------------------------------"

# 2. GIT & REPO STATUS
echo -e "${YELLOW}☁️  GitLab Sync Status [$PRIMARY_REPO]${NC}"
if [ -d "$PRIMARY_REPO" ]; then
    cd "$PRIMARY_REPO" || exit
    # Updated to fetch from 'gitlab' instead of 'origin'
    git fetch gitlab >/dev/null 2>&1
    BEHIND=$(git rev-list HEAD..gitlab/main --count 2>/dev/null || echo 0)
    AHEAD=$(git rev-list gitlab/main..HEAD --count 2>/dev/null || echo 0)

    if [ "$AHEAD" -eq 0 ] && [ "$BEHIND" -eq 0 ]; then
        echo -e "  GitLab      : ${GREEN}Synced${NC}"
    else
        [ "$AHEAD" -gt 0 ] && echo -e "  GitLab      : ${YELLOW}PUSH NEEDED ($AHEAD commits)${NC}"
        [ "$BEHIND" -gt 0 ] && echo -e "  GitLab      : ${BLUE}PULL NEEDED ($BEHIND commits)${NC}"
    fi
else
    echo -e "  GitLab      : ${RED}Primary repo not found!${NC}"
fi

# Local Status for both repos
for REPO in "$PRIMARY_REPO" "$SECONDARY_REPO"; do
    if [ -d "$REPO" ]; then
        cd "$REPO" || exit
        STATUS=$(git status --short)
        if [ -z "$STATUS" ]; then
            printf "  %-12s: ${GREEN}Clean${NC}\n" "$(basename "$REPO")"
        else
            printf "  %-12s: ${RED}Modified Files Present${NC}\n" "$(basename "$REPO")"
        fi
    fi
done

# 3. CONDITIONAL CHECKS (Desktop vs Server)
if [[ "$HOSTNAME" != "snowpi" ]]; then
    # --- FREEZER / DESKTOP CHECKS ---
    echo -e "\n${YELLOW}󰸉 Visual Engine Status${NC}"
    LIVE_WALL=$(awww query 2>/dev/null | grep -oP 'image: \K.*' | tr -d '[:space:]')
    PERSIST_WALL=$(cat "$HOME/.cache/skwd-wall/last_applied_wall.txt" 2>/dev/null)

    if [ -n "$LIVE_WALL" ] && [ "$LIVE_WALL" == "$PERSIST_WALL" ]; then
        echo -e "  Wallpaper   : ${GREEN}$(basename "$LIVE_WALL")${NC} (Synced)"
    else
        [ -n "$LIVE_WALL" ] && echo -e "  Active Wall : ${RED}$(basename "$LIVE_WALL")${NC}"
        [ -n "$PERSIST_WALL" ] && echo -e "  Saved Wall  : ${YELLOW}$(basename "$PERSIST_WALL")${NC}"
    fi

    echo -e "\n${YELLOW}󰏖 Versions & Integrity${NC}"
    check_version() {
        local name=$1; local cmd=$2
        raw_version=$(eval "$cmd" 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -n 1)
        [ -n "$raw_version" ] && printf "  %-12s: ${GREEN}%s${NC}\n" "$name" "$raw_version" || printf "  %-12s: ${RED}Error${NC}\n" "$name"
    }
    check_version "Hyprland" "hyprctl version | grep 'Tag'"
    check_version "skwd" "skwd status | jq -r '.version'"
    check_version "Matugen" "matugen --version"

    echo -e "\n${YELLOW}󱚧 Process Health${NC}"
    check_proc() {
        pgrep -x "$1" > /dev/null && printf "  %-12s: ${GREEN}RUNNING${NC}\n" "$1" || printf "  %-12s: ${RED}STOPPED${NC}\n" "$1"
    }
    check_proc "awww-daemon"
    check_proc "skwd-daemon"
    check_proc "swaync"

else
    # --- SNOWPI / SERVER CHECKS ---
    echo -e "\n${YELLOW}󱚧 Server & IoT Health${NC}"
    
    # Docker Check
    if systemctl is-active --quiet docker; then
        echo -e "  Docker      : ${GREEN}Active${NC}"
        # Home Assistant Container Check
        if docker ps | grep -q "homeassistant"; then
            echo -e "  Home Assist : ${GREEN}RUNNING (Docker)${NC}"
        else
            echo -e "  Home Assist : ${RED}STOPPED${NC}"
        fi
    else
        echo -e "  Docker      : ${RED}OFFLINE${NC}"
    fi

    # Pi-hole Check
    if command -v pihole >/dev/null; then
        pihole status | grep -q "enabled" && echo -e "  Pi-hole     : ${GREEN}Active${NC}" || echo -e "  Pi-hole     : ${RED}Disabled${NC}"
    fi

    # Backup Mount Check
    if mountpoint -q /mnt/backups; then
        echo -e "  Backup SSD  : ${GREEN}Mounted${NC} ($(du -sh /mnt/backups | awk '{print $1}'))"
    else
        echo -e "  Backup SSD  : ${RED}Not Found (/mnt/backups)${NC}"
    fi
fi

# 4. UNIVERSAL SYMLINK CHECK
echo -e "\n${YELLOW}󰏖 Symlink Integrity${NC}"
BROKEN=$(find ~/.config -maxdepth 2 -xtype l ! -path "*discord*" 2>/dev/null)
[ -z "$BROKEN" ] && echo -e "  Symlinks    : ${GREEN}Valid${NC}" || echo -e "  Symlinks    : ${RED}Broken Links Found!${NC}"

echo "---------------------------------------------------"
echo -e "${BLUE}Audit Complete.${NC}"
