#!/bin/bash
# -----------------------------------------------------------------------
# ❄️  snow-dots.sh — Interactive Dotfiles Installer
#     https://github.com/Snowiseverything/snowdots
# -----------------------------------------------------------------------
set -e

# ── Colors ──────────────────────────────────────────────────────────
BOLD=$'\033[1m'
CYAN=$'\033[0;36m'
BLUE=$'\033[0;34m'
WHITE=$'\033[0;37m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
RED=$'\033[0;31m'
NC=$'\033[0m'

# ── ASCII ────────────────────────────────────────────────────────────
SNOWFLAKE='❄️'
LOGO="
${CYAN}   ▄▄▄▄▄▄▄▄▄▄▄  ${WHITE}╷${NC}
${CYAN}  █           █ ${WHITE}│${NC}
${CYAN} █   ${BOLD}SNOWDOTS${NC}${CYAN}  █ ${WHITE}│${NC}  ${BLUE}Hyprland dotfiles${NC}
${CYAN}  █           █ ${WHITE}│${NC}  ${BLUE}Arch / fish / kitty${NC}
${CYAN}   ▀▀▀▀▀▀▀▀▀▀▀  ${WHITE}╵${NC}
"

DISTRO=""
PKG_CMD=""
USER_SHELL=""

# ── Helpers ─────────────────────────────────────────────────────────
info()  { echo -e "  ${CYAN}${SNOWFLAKE}${NC} $1"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; }

press_enter() {
    echo ""
    read -rp "  Press Enter to continue..."
}

detect_distro() {
    if command -v pacman &>/dev/null; then
        DISTRO="arch"
        PKG_CMD="sudo pacman -S --needed --noconfirm"
        AUR_CMD=""
        if command -v yay &>/dev/null; then
            AUR_CMD="yay -S --needed --noconfirm"
        elif command -v paru &>/dev/null; then
            AUR_CMD="paru -S --needed --noconfirm"
        fi
    elif command -v apt &>/dev/null; then
        DISTRO="debian"
        PKG_CMD="sudo apt install -y"
    elif command -v dnf &>/dev/null; then
        DISTRO="fedora"
        PKG_CMD="sudo dnf install -y"
    else
        warn "Unsupported distro. Symlinks only, no package install."
        DISTRO="unknown"
    fi
}

detect_shell() {
    local shell_name
    shell_name=$(basename "$SHELL" 2>/dev/null || echo "bash")
    case "$shell_name" in
        fish) USER_SHELL="fish" ;;
        bash|zsh) USER_SHELL="bash" ;;
        *) USER_SHELL="bash" ;;
    esac
}

# ── Main ────────────────────────────────────────────────────────────
clear
echo -e "$LOGO"
echo -e "  ${BOLD}${SNOWFLAKE} Interactive Dotfiles Installer${NC}"
echo ""
echo "  This will set up my Hyprland dotfiles on your system."
echo "  You'll choose what to install at each step."
echo ""

# ── 1. Prerequisites check ────────────────────────────────────────
info "Checking system..."
detect_distro
detect_shell
ok "Detected: $DISTRO | Shell: $USER_SHELL"
echo ""

# ── 2. Backup ────────────────────────────────────────────────────
echo "  ${BOLD}${SNOWFLAKE} Backup Current Config${NC}"
echo "  Before making changes, SnowDots will backup your current"
echo "  dotfiles so you can restore if you don't like the setup."
echo ""
read -rp "  Backup current config before proceeding? [Y/n] " do_backup
if [[ ! "$do_backup" =~ ^[nN] ]]; then
    bash "$REPO_DIR/scripts/backup-dots.sh" 2>/dev/null || {
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        bash "$SCRIPT_DIR/backup-dots.sh"
    }
else
    warn "Skipping backup. You won't have a restore point."
    echo ""
fi

# ── 3. Clone repo ─────────────────────────────────────────────────
REPO_DIR="$HOME/Dotfiles"
INSTALL_REPO=true

if [ -d "$REPO_DIR" ]; then
    echo -e "  ${YELLOW}⚠${NC} Dotfiles already exists at $REPO_DIR"
    read -rp "  Overwrite? (backup will be moved) [y/N] " overwrite
    if [[ "$overwrite" =~ ^[yY] ]]; then
        mv "$REPO_DIR" "${REPO_DIR}.bak-$(date +%s)"
        info "Backed up to ${REPO_DIR}.bak-*"
    else
        INSTALL_REPO=false
    fi
fi

if $INSTALL_REPO; then
    info "Cloning repo..."
    git clone https://github.com/Snowiseverything/snowdots.git "$REPO_DIR" 2>/dev/null || \
        git clone https://gitlab.com/sn0wman/snowdots.git "$REPO_DIR"
    ok "Cloned to $REPO_DIR"
fi
echo ""

# ── 4. Package selection ──────────────────────────────────────────
echo "  ${BOLD}${SNOWFLAKE} Package Selection${NC}"
echo "  (you can skip any group, install later with pacman)"
echo ""

case "$DISTRO" in
    arch)
        read -rp "  ${SNOWFLAKE} Install core WM components? (hyprland, fish, kitty, waybar) [Y/n] " choice
        if [[ ! "$choice" =~ ^[nN] ]]; then
            $PKG_CMD hyprland fish kitty waybar wofi fuzzel swaync dunst wlogout \
                        starship fastfetch grim slurp swappy wl-clipboard \
                        polkit-kde-agent xdg-desktop-portal-hyprland \
                        ttf-jetbrains-mono-nerd ttf-meslo-nerd noto-fonts-emoji
            ok "Core packages installed"
        fi

        if [ -n "$AUR_CMD" ]; then
            read -rp "  ${SNOWFLAKE} Install AUR extras? (matugen-bin, hyprland-guiutils) [Y/n] " choice
            if [[ ! "$choice" =~ ^[nN] ]]; then
                $AUR_CMD matugen-bin hyprland-guiutils 2>&1 | tail -1
                ok "AUR extras installed"
            fi
        else
            warn "No AUR helper found (yay/paru). Install matugen-bin manually."
        fi

        read -rp "  ${SNOWFLAKE} Install extra fonts? (cascadia-code, fantasque-nerd) [Y/n] " choice
        if [[ ! "$choice" =~ ^[nN] ]]; then
            $PKG_CMD ttf-cascadia-code-nerd ttf-fantasque-nerd ttf-material-design-icons-desktop-git
            ok "Fonts installed"
        fi

        read -rp "  ${SNOWFLAKE} Install apps? (thunar, firefox, rofi) [y/N] " choice
        if [[ "$choice" =~ ^[yY] ]]; then
            $PKG_CMD thunar firefox rofi 2>&1 | tail -1
            ok "Apps installed"
        fi
        ;;

    debian|fedora)
        warn "Limited package support for $DISTRO. Installing essentials..."
        $PKG_CMD fish kitty starship fastfetch grim slurp wl-clipboard \
                 fonts-jetbrains-mono fonts-noto-color-emoji 2>&1 | tail -1
        ok "Available packages installed"
        warn "Hyprland must be installed manually on $DISTRO"
        ;;

    *)
        warn "Skipping package install. Symlinks only."
        ;;
esac

# ── 5. Shell setup ────────────────────────────────────────────────
echo "  ${BOLD}${SNOWFLAKE} Shell Setup${NC}"
if command -v fish &>/dev/null; then
    read -rp "  Set fish as default shell? [y/N] " choice
    if [[ "$choice" =~ ^[yY] ]]; then
        chsh -s "$(command -v fish)" 2>/dev/null && ok "Default shell: fish" || warn "chsh failed (maybe already fish)"
    fi

    read -rp "  Install fisher + plugins? (autopair, pure prompt) [Y/n] " choice
    if [[ ! "$choice" =~ ^[nN] ]]; then
        if ! command -v fisher &>/dev/null; then
            fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher" 2>/dev/null
        fi
        fish -c "fisher install jorgebucaran/autopair edouard-lopez/pure-func" 2>/dev/null
        ok "Fisher + plugins installed"
    fi
else
    warn "fish not installed. Install it and re-run this step."
fi

# Add $HOME/.local/bin to PATH for current shell
if [[ "$USER_SHELL" == "fish" ]]; then
    fish -c "fish_add_path $HOME/.local/bin" 2>/dev/null
else
    rcfile="$HOME/.bashrc"
    [[ "$USER_SHELL" == "zsh" ]] && rcfile="$HOME/.zshrc"
    if [ -f "$rcfile" ]; then
        if ! grep -q '\.local/bin' "$rcfile" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rcfile"
            ok "Added ~/.local/bin to PATH in $rcfile"
        fi
    fi
fi
echo ""

# ── 6. Symlinks ──────────────────────────────────────────────────
echo "  ${BOLD}${SNOWFLAKE} Config Symlinks${NC}"
echo "  Linking $REPO_DIR configs to ~/.config/"
echo ""

SYMLINKS=(
    "fish:$REPO_DIR/fish"
    "kitty:$REPO_DIR/kitty"
    "fastfetch:$REPO_DIR/fastfetch"
    "hypr/hyprland.conf:$REPO_DIR/hypr/hyprland.conf"
    "hypr/hypridle.conf:$REPO_DIR/hypr/hypridle.conf"
    "starship.toml:$REPO_DIR/starship/starship.toml"
    "mm/config.toml:$REPO_DIR/mm/config.toml"
)

link_config() {
    local target="$1"
    local dest="$HOME/.config/$target"

    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ]; then
        rm "$dest"
        info "Replaced symlink: $dest"
    elif [ -f "$dest" ] || [ -d "$dest" ]; then
        mv "$dest" "${dest}.bak-$(date +%s)"
        warn "Backed up existing: $dest"
    fi

    ln -sf "$2" "$dest"
    ok "Linked ~/.config/$target"
}

for entry in "${SYMLINKS[@]}"; do
    target="${entry%%:*}"
    source="${entry#*:}"
    if [ -e "$source" ]; then
        link_config "$target" "$source"
    else
        warn "Source missing: $source"
    fi
done

# Script symlinks
mkdir -p "$HOME/.local/bin"
for script in "$REPO_DIR/scripts"/*.sh "$REPO_DIR/scripts/snow-dots"; do
    name=$(basename "$script")
    if [ -L "$HOME/.local/bin/$name" ]; then
        rm "$HOME/.local/bin/$name"
    fi
    ln -sf "$script" "$HOME/.local/bin/$name"
done
ln -sf "$REPO_DIR/scripts/dotsync" "$HOME/.local/bin/dotsync"
ok "Scripts linked to ~/.local/bin"

echo ""

# ── 7. matchmaker ─────────────────────────────────────────────────
echo "  ${BOLD}${SNOWFLAKE} Optional Tools${NC}"
read -rp "  Install matchmaker fuzzy finder? (requires cargo) [y/N] " choice
if [[ "$choice" =~ ^[yY] ]]; then
    if command -v cargo &>/dev/null; then
        cargo install matchmaker-cli 2>&1 | tail -1
        mkdir -p "$HOME/.config/fish/conf.d"
        cat > "$HOME/.config/fish/conf.d/matchmaker.fish" << 'FISHEOF'
if status is-interactive
    bind \cf 'mm --cwd $PWD | read -l path; and cd "$path"; and commandline -f repaint'
    bind \cr 'mm --include-dirs --cwd $PWD | read -l path; and cd "$path"; and commandline -f repaint'
    bind \ec 'mm --dirs-only --cwd $PWD | read -l path; and cd "$path"; and commandline -f repaint'
end
FISHEOF
        ok "matchmaker + fish bindings installed"
    else
        warn "cargo not found. Install rustup first."
    fi
fi
echo ""

# ── 8. Done + Restore Info ───────────────────────────────────────
echo "  ${BOLD}${SNOWFLAKE}${BOLD} Setup Complete${NC}"
echo ""
echo -e "  ${GREEN}══════════════════════════════════════${NC}"
echo -e "  ${GREEN}  Reload your shell:${NC}"
if [[ "$USER_SHELL" == "fish" ]] || command -v fish &>/dev/null; then
    echo -e "  ${GREEN}    exec fish${NC}"
    echo -e "  ${GREEN}    source ~/.config/fish/config.fish${NC}"
else
    echo -e "  ${GREEN}    source ~/.bashrc${NC}"
fi
echo -e "  ${GREEN}══════════════════════════════════════${NC}"
echo ""
echo "  What now?"
echo "    ${CYAN}•${NC} Run ${BOLD}snow-dots backup${NC} to backup current config"
echo "    ${CYAN}•${NC} Run ${BOLD}snow-dots restore${NC} to restore from backup"
echo "    ${CYAN}•${NC} Run ${BOLD}dotsync${NC} to pull latest"
echo "    ${CYAN}•${NC} Edit configs in ~/Dotfiles/"
echo "    ${CYAN}•${NC} Read the README for keybinds"
echo ""

echo "  ${SNOWFLAKE} Enjoy!"
