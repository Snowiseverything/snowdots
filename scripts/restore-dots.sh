#!/bin/bash
# -----------------------------------------------------------------------
# ❄️  restore-dots.sh — Restore dotfiles from a SnowDots backup
# Usage: restore-dots.sh [backup-dir]
#        If no backup dir given, lists available backups and prompts.
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
fail()  { echo -e "  ${RED}✗${NC} $1"; }

# Find available backups
backups=()
while IFS= read -r -d '' dir; do
    backups+=("$dir")
done < <(find "$HOME" -maxdepth 1 -type d -name '.dotfiles-backup-*' -print0 | sort -rz)

if [ ${#backups[@]} -eq 0 ]; then
    fail "No backups found in $HOME/.dotfiles-backup-*"
    echo "  Run 'snow-dots backup' first."
    exit 1
fi

# Pick backup dir
if [ -n "$1" ]; then
    BACKUP_DIR="$1"
    if [ ! -d "$BACKUP_DIR" ]; then
        fail "Backup dir not found: $BACKUP_DIR"
        exit 1
    fi
else
    echo ""
    echo "  ${BOLD}${SNOWFLAKE} Available Backups${NC}"
    echo ""
    for i in "${!backups[@]}"; do
        size=$(du -sh "${backups[$i]}" 2>/dev/null | cut -f1)
        echo "  $((i+1)). ${backups[$i]}  (${size})"
    done
    echo ""
    read -rp "  Select backup to restore [1-${#backups[@]}]: " sel
    sel=$((sel-1))
    if [ "$sel" -lt 0 ] || [ "$sel" -ge "${#backups[@]}" ]; then
        fail "Invalid selection"
        exit 1
    fi
    BACKUP_DIR="${backups[$sel]}"
fi

echo ""
echo "  ${BOLD}${SNOWFLAKE} Restoring from: ${CYAN}$BACKUP_DIR${NC}"
echo "  ${YELLOW}⚠ This will overwrite current config files!${NC}"
read -rp "  Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[yY] ]]; then
    info "Restore cancelled."
    exit 0
fi

restored=0

# Restore ~/.config dirs
if [ -d "$BACKUP_DIR/.config" ]; then
    for item in "$BACKUP_DIR/.config"/*; do
        name=$(basename "$item")
        target="$HOME/.config/$name"
        if [ -L "$target" ] || [ -f "$target" ] || [ -d "$target" ]; then
            rm -rf "$target"
        fi
        mkdir -p "$(dirname "$target")"
        cp -r "$item" "$target" 2>/dev/null
        ok "Restored .config/$name"
        restored=1
    done
fi

# Restore .local/bin
if [ -d "$BACKUP_DIR/.local/bin" ]; then
    mkdir -p "$HOME/.local/bin"
    for script in "$BACKUP_DIR/.local/bin"/*; do
        name=$(basename "$script")
        if [ -L "$HOME/.local/bin/$name" ]; then
            rm "$HOME/.local/bin/$name"
        fi
        cp "$script" "$HOME/.local/bin/$name" 2>/dev/null
    done
    ok "Restored ~/.local/bin scripts"
    restored=1
fi

# Restore shell rc files
for rc in "$BACKUP_DIR"/.bashrc "$BACKUP_DIR"/config.fish "$BACKUP_DIR"/.zshrc; do
    if [ -f "$rc" ]; then
        case "$(basename "$rc")" in
            .bashrc) cp "$rc" "$HOME/.bashrc" 2>/dev/null; ok "Restored .bashrc" ;;
            config.fish) cp "$rc" "$HOME/.config/fish/config.fish" 2>/dev/null; ok "Restored fish/config.fish" ;;
            .zshrc) cp "$rc" "$HOME/.zshrc" 2>/dev/null; ok "Restored .zshrc" ;;
        esac
        restored=1
    fi
done

if [ "$restored" -eq 0 ]; then
    warn "No files found in backup to restore."
else
    echo ""
    echo "  ${SNOWFLAKE} Restore complete. Reload your shell:"
    echo "    ${CYAN}exec \$SHELL${NC}"
    echo ""
fi
