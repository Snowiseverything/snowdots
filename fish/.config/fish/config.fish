# ── CachyOS Base ──────────────────────────────
source /usr/share/cachyos-fish-config/cachyos-config.fish

# ── Shell & Starship ──────────────────────────
starship init fish | source

# Merge pywal palette into starship
if test -f ~/.config/starship-palette.toml
    cat ~/.config/starship.toml ~/.config/starship-palette.toml > /tmp/starship-merged.toml
    set -x STARSHIP_CONFIG /tmp/starship-merged.toml
end

# ── Dotfiles Management ───────────────────────
alias dotfiles='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias dotpush='cd ~/.dotfiles && git add . && git commit -m "update" && git push'

# ── Edit Configs (Source-Direct) ──────────────
function edit-fish
    nano ~/Dotfiles/fish/.config/fish/config.fish
    and source ~/.config/fish/config.fish
end

function edit-hypr
    # This now points to your visible master repo
    nano ~/Dotfiles/hypr/.config/hypr/hyprland.conf
end

function edit-starship
    # Assuming starship.toml is in your Dotfiles root or a starship folder
    nano ~/Dotfiles/starship/.config/starship.toml 2>/dev/null
    or nano ~/Dotfiles/starship.toml
end

function edit-kitty
    # Note: Using the .config/kitty path inside your dotfiles
    nano ~/.dotfiles/.config/kitty/kitty.conf
end

function edit-ssh
    nano ~/.ssh/config
end

# ── Personal Overrides ────────────────────────
if status is-interactive
    abbr --erase ff 2>/dev/null
    abbr -a ff fastfetch
end

# ── Maptoposter ───────────────────────────────
function mapgen
    /usr/bin/uv --directory $HOME/src/maptoposter run python $HOME/src/maptoposter/create_map_poster.py \
        --city "Erbil" --country "Iraq" --display-city "Hawler | هەولێر" --display-country "KRG" \
        --distance 8000 --theme "cyber_game" --width 16 --height 16 --font-family "Noto Sans Arabic" $argv
end
