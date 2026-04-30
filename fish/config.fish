# ── CachyOS Base ──────────────────────────────
# Silently source CachyOS defaults if they exist
source /usr/share/cachyos-fish-config/cachyos-config.fish 2>/dev/null

# ── Quick Paths (Stow-Compatible) ─────────────
set -gx DOTS ~/Dotfiles
set -gx HYPR $DOTS/hypr/.config/hypr/hyprland.conf
set -gx FISHCONF $DOTS/fish/.config/fish/config.fish

# ── Shell & Starship ──────────────────────────
set -x STARSHIP_CONFIG ~/.config/starship.toml
starship init fish | source

# ── Dotfiles Management ───────────────────────
# Pushes to both backup and origin as per your recent workflow
alias dotsync='cd $DOTS && git add . && git commit -m "update $(date +%Y-%m-%d)" && git push backup main && git push origin main'
alias dotpull='cd $DOTS && git fetch --all && git reset --hard origin/main'

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
