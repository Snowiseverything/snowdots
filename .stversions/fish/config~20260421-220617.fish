# ── CachyOS Base ──────────────────────────────
# Load vendor config
source /usr/share/cachyos-fish-config/cachyos-config.fish

# Fix for done.fish: Force a numeric value and silence notifications if they error
set -g done_notify_all_processes 0
set -g __done_initial_window_id (hyprctl activewindow -j | jq '.address' | string replace -r '\D' '' ; or echo 0)

# If the window ID is still empty or non-numeric, just set it to 0 to stop the 'test' error
if not string match -qr '^[0-9]+$' "$__done_initial_window_id"
    set -g __done_initial_window_id 0
end

# ── Dotfiles ──────────────────────────────────
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dotrestore='bash ~/.local/bin/dotfiles-restore.sh'

# ── Shell ─────────────────────────────────────
starship init fish | source

# Merge pywal palette into starship
if test -f ~/.config/starship-palette.toml
    cat ~/.config/starship.toml ~/.config/starship-palette.toml > /tmp/starship-merged.toml
    set -x STARSHIP_CONFIG /tmp/starship-merged.toml
end

# ── Edit Configs ──────────────────────────────
function edit-hypr
    nano ~/.config/hypr/hyprland.conf
end

function edit-fish
    nano ~/.config/fish/config.fish
    and source ~/.config/fish/config.fish
end

function edit-kitty
    nano ~/.config/kitty/kitty.conf
end

function edit-ssh
    nano ~/.ssh/config
end

function edit-local
    nano ~/.local/bin/dotfiles-autopush.sh
end

function edit-shell
    nano ~/.config/caelestia/shell.json
    and hyprctl reload
    and killall caelestia
    and caelestia shell -d &
    disown
end

# ── Connections ───────────────────────────────
alias snowpi='/usr/bin/ssh snowpi'

# ── Personal Overrides ────────────────────────
# This section is at the bottom to ensure it wins 
# against any vendor-defined aliases or abbreviations.

if status is-interactive
    # We use --erase first to clear any old definitions of 'ff'
    abbr --erase ff 2>/dev/null
    # ---> CHANGED: This will now expand 'ff' to 'fastfetch' when you hit Space
    abbr -a ff fastfetch
end

# ── Maptoposter shorcuts ────────────────────────
# ── Maptoposter shortcuts ────────────────────────
function mapgen
    set -l search_city "Erbil"
    set -l search_country "Iraq"
    set -l display_name "Hawler | هەولێر"
    set -l default_dist 8000
    set -l default_theme "cyber_game"
    
    # 16x16 is the "Golden Square" for Erbil's rings
    set -l default_width 16
    set -l default_height 16

    /usr/bin/uv --directory $HOME/src/maptoposter run python $HOME/src/maptoposter/create_map_poster.py \
        --city "$search_city" \
        --country "$search_country" \
        --display-city "$display_name" \
        --display-country "KRG" \
        --distance $default_dist \
        --theme $default_theme \
        --width $default_width \
        --height $default_height \
        --font-family "Noto Sans Arabic" \
        $argv
end

# View the latest generated map
function mapview
    set latest (command ls -t ~/src/maptoposter/posters/*.png)[1]
    imv $latest
end
