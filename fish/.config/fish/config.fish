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

# ── Edit Functions (Fixed Paths) ──────────────
function edit-fish
    nano ~/Dotfiles/fish/.config/fish/config.fish # Adjusted to your real structure
    and source ~/.config/fish/config.fish
    and echo "󰈺 Fish config reloaded!"
end

function edit-starship
    nano ~/Dotfiles/starship.toml
end

function edit-hypr
    nano ~/Dotfiles/hypr/.config/hypr/hyprland.conf
end

# ── Maptoposter (Hawler | هەولێر) ──────────────
function mapgen
    /usr/bin/uv --directory $HOME/src/maptoposter run python $HOME/src/maptoposter/create_map_poster.py \
        --city "Erbil" --country "Iraq" --display-city "Hawler | هەولێر" --display-country "KRG" \
        --distance 8000 --theme "cyber_game" --width 16 --height 16 --font-family "Noto Sans Arabic" $argv
end
