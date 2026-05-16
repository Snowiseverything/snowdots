########################################################################
##  SnowDots — Fish Config                             Version: v1.0.0    ##
##  Last Edited: 2026-05-02                                           ##
########################################################################

# ── SnowPi Independent Config ─────────────────

# ── Shell & Starship ──────────────────────────
# Point Starship specifically to the Pi's config
set -x STARSHIP_CONFIG ~/.config/starship.toml
starship init fish | source

# ── SnowPi Dotfiles Management ────────────────
# These now point to the Pi-specific repo
alias dotsync='~/Dotfiles/scripts/dotsync'

# ── System Info ───────────────────────────────
alias ff="fastfetch --logo raspberrypi --logo-color-1 red --logo-color-2 green"

if status is-interactive
    # Show your custom dashboard banner
    /usr/local/bin/snowpi-banner
end

# ── Edit Functions (Pi-Specific) ──────────────
function edit-fish
    nano ~/Dotfiles/fish/.config/fish/config.fish
    and source ~/.config/fish/config.fish
    and echo "❄️ SnowPi Fish config reloaded!"
end

function edit-starship
    nano ~/Dotfiles/starship/.config/starship.toml
end

# ── Scripts & Backups ─────────────────────────
alias backup-now='~/Dotfiles/scripts/fortress_backup.sh'
fish_add_path ~/Dotfiles/scripts
set -gx STARSHIP_CONFIG ~/.config/starship.toml

# pnpm
set -gx PNPM_HOME "/home/snow/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"
