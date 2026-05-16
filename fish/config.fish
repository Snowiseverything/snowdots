########################################################################
##  SnowDots — Fish Config (Unified)                                  ##
########################################################################

# ── Shared: both machines ────────────────────
set -x STARSHIP_CONFIG ~/.config/starship.toml
starship init fish | source

alias dotsync='~/Dotfiles/scripts/dotsync'
fish_add_path ~/Dotfiles/scripts
fish_add_path ~/.local/bin

# ── Machine-Specific ─────────────────────────
switch (hostname)
    case freezer
        alias ff="fastfetch"

    case snowpi
        alias ff="fastfetch --logo raspberrypi --logo-color-1 red --logo-color-2 green"

        if status is-interactive
            /usr/local/bin/snowpi-banner
        end

        function edit-fish
            nano ~/Dotfiles/fish/config.fish
            and source ~/.config/fish/config.fish
            and echo "Fish config reloaded"
        end

        function edit-starship
            nano ~/Dotfiles/starship/starship.toml
        end

        alias backup-now='~/Dotfiles/scripts/fortress_backup.sh'

        set -gx PNPM_HOME "$HOME/.local/share/pnpm"
        if not string match -q -- $PNPM_HOME $PATH
            set -gx PATH "$PNPM_HOME" $PATH
        end
end
