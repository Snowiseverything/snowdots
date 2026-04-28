# ── CachyOS Base ──────────────────────────────
source /usr/share/cachyos-fish-config/cachyos-config.fish 2>/dev/null

# ── Shell & Starship ──────────────────────────
# Hide the Node version (v20.20.2) in prompt
set -x STARSHIP_CONFIG ~/.config/starship.toml
starship init fish | source

# ── Dotfiles Management ───────────────────────
alias dotsync='cd ~/Dotfiles && git add . && git commit -m "update $(date +%Y-%m-%d)" && git push backup main && git push origin main'
alias dotpull='cd ~/Dotfiles && git fetch --all && git reset --hard origin/main'

# ── Host Detection ────────────────────────────
set MY_HOST (hostname)
if test "$MY_HOST" = "snowpi"
    alias ff="fastfetch --logo raspberrypi --logo-color-1 red --logo-color-2 green"
    if status is-interactive
        /usr/local/bin/snowpi-banner
    end
else
    alias ff="fastfetch --logo cachyos"
end

# ── Edit Functions (Stow-Compatible) ──────────
function edit-fish
    # Points exactly to where Stow gets its data
    nano ~/Dotfiles/fish/.config/fish/config.fish
    and source ~/.config/fish/config.fish
    and echo "❄️ Fish config reloaded and synced!"
end

function edit-alias
    nano ~/Dotfiles/fish/.config/fish/aliases.fish
    and source ~/.config/fish/config.fish
end

function edit-starship
    nano ~/Dotfiles/starship/starship.toml
end

function edit-kitty
    nano ~/Dotfiles/kitty/.config/kitty/kitty.conf
end

function edit-hypr
    # This matches your Stow structure: Dotfiles/hypr/.config/hypr/
    nano ~/Dotfiles/hypr/.config/hypr/hyprland.conf
end

# ── Maptoposter (Hawler | هەولێر) ──────────────
function mapgen
    /usr/bin/uv --directory $HOME/src/maptoposter run python $HOME/src/maptoposter/create_map_poster.py \
        --city "Erbil" --country "Iraq" --display-city "Hawler | هەولێر" --display-country "KRG" \
        --distance 8000 --theme "cyber_game" --width 16 --height 16 --font-family "Noto Sans Arabic" $argv
end

# ── Host Detection & Machine Specifics ────────
set -l host (hostname)

if test "$host" = "snowpi"
    # SnowPi: The Backup Vault
    alias ff="fastfetch --logo raspberrypi --logo-color-1 red --logo-color-2 green"
    alias backup-now='~/Dotfiles/scripts/fortress_backup.sh'
    set -gx DOT_ROLE "Backup Node"
    fish_add_path ~/Dotfiles/scripts
    if status is-interactive
        /usr/local/bin/snowpi-banner
    end
else
    # CachyOS: The Daily Driver
    alias ff="fastfetch --logo cachyos"
    alias dotsync='cd ~/Dotfiles && git add . && git commit -m "update $(date +%Y-%m-%d)" && git push origin main'
    set -gx DOT_ROLE "Main Desktop"
end
