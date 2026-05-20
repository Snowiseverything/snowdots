#!/bin/bash
# -----------------------------------------------------------------------
# ❄️  SnowDots Installer — curl | bash bootstrap
#     Usage:
#       curl -sL https://raw.githubusercontent.com/Snowiseverything/snowdots/main/scripts/install.sh | bash
#       curl -sL https://gitlab.com/sn0wman/snowdots/-/raw/main/scripts/install.sh | bash
# -----------------------------------------------------------------------
set -e

REPO_DIR="$HOME/Dotfiles"
REPO_URL="https://github.com/Snowiseverything/snowdots.git"
REPO_FALLBACK="https://gitlab.com/sn0wman/snowdots.git"

echo ""
echo "  ❄️  SnowDots Bootstrap Installer"
echo ""

# ── Check git ────────────────────────────────────────────────────
if ! command -v git &>/dev/null; then
    echo "  ⚠ git not found. Installing..."
    if command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm git
    elif command -v apt &>/dev/null; then
        sudo apt install -y git
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git
    else
        echo "  ✗ Install git manually, then re-run this script."
        exit 1
    fi
fi

# ── Clone ─────────────────────────────────────────────────────────
if [ -d "$REPO_DIR" ]; then
    echo "  ⚠ $REPO_DIR already exists."
    read -rp "  Overwrite? (backup will be renamed) [y/N] " overwrite
    if [[ "$overwrite" =~ ^[yY] ]]; then
        mv "$REPO_DIR" "${REPO_DIR}.bak-$(date +%s)"
        echo "  ✓ Backed up old Dotfiles"
    else
        echo "  Using existing $REPO_DIR"
    fi
fi

if [ ! -d "$REPO_DIR" ]; then
    echo "  📦 Cloning repo..."
    if ! git clone "$REPO_URL" "$REPO_DIR" 2>/dev/null; then
        echo "  ⚠ GitHub failed, trying GitLab..."
        git clone "$REPO_FALLBACK" "$REPO_DIR"
    fi
    echo "  ✓ Cloned to $REPO_DIR"
fi

echo ""

# ── Hand off to snow-dots ───────────────────────────────────────
SNOW_DOTS="$REPO_DIR/scripts/snow-dots"
if [ -f "$SNOW_DOTS" ]; then
    echo "  ❄️  Launching SnowDots installer..."
    echo ""
    exec bash "$SNOW_DOTS" install
else
    echo "  ⚠ snow-dots not found, falling back to snow-dots.sh..."
    exec bash "$REPO_DIR/scripts/snow-dots.sh"
fi
