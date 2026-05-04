########################################################################
##  SnowDots — Snowfish                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

# ── CachyOS Base ──────────────────────────────
# Silently source CachyOS defaults if they exist
source /usr/share/cachyos-fish-config/cachyos-config.fish 2>/dev/null
set -g __done_initial_window_id 0

# ── Quick Paths (Stow-Compatible) ─────────────
set -gx DOTS ~/Dotfiles
set -gx SCRIPT_DIR $DOTS/scripts
set -gx HYPR $DOTS/hypr/hyprland.conf
set -gx FISHCONF $DOTS/fish/config.fish

# ── Shell & Starship ──────────────────────────
set -x STARSHIP_CONFIG ~/.config/starship.toml
starship init fish | source

# ── Script Execution ──
alias dotsync="bash $SCRIPT_DIR/dotsync"
alias dotpull="bash $SCRIPT_DIR/dotpull"
alias check="fish $DOTS/bin/check-dots.fish"  # Keep this if bin is separate, or move it too
alias fixme="bash $SCRIPT_DIR/fix-me.sh"
alias sun-toggle="bash $SCRIPT_DIR/sun-schedule.sh toggle"
alias ai='env GEMINI_SYSTEM_MD=~/GEMINI.md gemini'

# ── Host Detection ────────────────────────────
set MY_HOST (hostname)
if test "$MY_HOST" = "snowpi"
    alias ff="fastfetch --logo raspberrypi --logo-color-1 red --logo-color-2 green"
    set -gx STARSHIP_DISTRO "󰐿"  # Raspberry Pi Icon
    if status is-interactive
        /usr/local/bin/snowpi-banner
    end
else
    alias ff="fastfetch --logo cachyos"
    set -gx STARSHIP_DISTRO "󰣇"  # Arch/CachyOS Icon
end

# ── Edit Functions ────────────────────────────
# These point directly to your Dotfiles to ensure Git tracks changes immediately

function edit-fish
    nano $FISHCONF
    and source ~/.config/fish/config.fish
    and echo "❄️ Fish config reloaded!"
end

function edit-hypr
    nano $HYPR
end

function edit-starship
    nano $DOTS/starship/.config/starship.toml
end

function edit-kitty
    nano $DOTS/kitty/.config/kitty/kitty.conf
end

# ── Maptoposter (Hawler | هەولێر) ──────────────
function mapgen
    /usr/bin/uv --directory $HOME/src/maptoposter run python $HOME/src/maptoposter/create_map_poster.py \
        --city "Erbil" --country "Iraq" --display-city "Hawler | هەولێر" --display-country "KRG" \
        --distance 8000 --theme "cyber_game" --width 16 --height 16 --font-family "Noto Sans Arabic" $argv
end

# Start ssh-agent if not running
if not set -q SSH_AUTH_SOCK
    eval (ssh-agent -c) > /dev/null
end

# Add the key quietly if it's not already there
ssh-add -l > /dev/null 2>&1
if test $status -eq 1
    ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
end
