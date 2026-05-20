#!/bin/bash
# -----------------------------------------------------------------------
# ❄️  backup-dots.sh — Backup current dotfiles before SnowDots install
# Usage: backup-dots.sh
# -----------------------------------------------------------------------
set -e

BOLD=$'\033[1m'
CYAN=$'\033[0;36m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m'
SNOWFLAKE='❄️'

info()  { echo -e "  ${CYAN}${SNOWFLAKE}${NC} $1"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }

BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo ""
echo -e "  ${BOLD}${SNOWFLAKE} Backing up current dotfiles...${NC}"
echo "  Target: $BACKUP_DIR"
echo ""

configs=(
    "$HOME/.config/hypr"
    "$HOME/.config/fish"
    "$HOME/.config/kitty"
    "$HOME/.config/starship.toml"
    "$HOME/.config/fastfetch"
    "$HOME/.config/waybar"
    "$HOME/.config/swaync"
    "$HOME/.config/dunst"
    "$HOME/.config/wofi"
    "$HOME/.config/fuzzel"
    "$HOME/.config/wlogout"
    "$HOME/.local/bin"
)

for path in "${configs[@]}"; do
    if [ -e "$path" ]; then
        rel="${path#$HOME/}"
        dest_dir="$BACKUP_DIR/$rel"
        mkdir -p "$(dirname "$dest_dir")"
        cp -rL "$path" "$dest_dir" 2>/dev/null
        ok "Backed up $rel"
    fi
done

for rc in "$HOME/.bashrc" "$HOME/.config/fish/config.fish" "$HOME/.zshrc"; do
    if [ -f "$rc" ]; then
        cp "$rc" "$BACKUP_DIR/" 2>/dev/null
        ok "Backed up $(basename "$rc")"
    fi
done

echo ""
echo -e "  ${SNOWFLAKE} Backup complete: ${CYAN}$BACKUP_DIR${NC}"
echo -e "  ${SNOWFLAKE} Restore with: ${CYAN}snow-dots restore${NC}"
echo ""
