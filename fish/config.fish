########################################################################
##  SnowDots — Fish Config (Unified)                                  ##
########################################################################

# ── Shared: both machines ────────────────────
set -x STARSHIP_CONFIG ~/.config/starship.toml
starship init fish | source

source ~/.config/fish/aliases.fish

alias dotsync='~/Dotfiles/scripts/dotsync'
fish_add_path ~/Dotfiles/scripts
fish_add_path ~/.local/bin
fish_add_path ~/scripts

# ── Machine-Specific ─────────────────────────
switch (hostname)
    case freezer
        alias ff="fastfetch"

        if status is-interactive
            fastfetch
        end

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
