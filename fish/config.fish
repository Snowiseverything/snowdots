########################################################################
##  SnowDots — Fish Config (Unified)                                  ##
########################################################################

# ── Shared: both machines ────────────────────
set -x STARSHIP_CONFIG ~/.config/starship.toml
set -x SAM_STEAM_INSTALL_ROOT /home/snow/.local/share/Steam
starship init fish | source
if type -q zoxide
    zoxide init fish | source
end

source ~/.config/fish/aliases.fish

function dotsync
    ~/Dotfiles/scripts/dotsync $argv
    and ~/scripts/oc-sync.sh --sessions
end
fish_add_path ~/Dotfiles/scripts
fish_add_path ~/.local/bin
fish_add_path ~/scripts

# ── Machine-Specific ─────────────────────────
switch (hostname)
    case freezer
        set fish_greeting

        alias ff="fastfetch"

        if status is-interactive
            fastfetch
        end

		alias luatools="curl -fsSL https://raw.githubusercontent.com/Star123451/LuaToolsLinux/main/install.sh | bash"


    case snowpi
        set fish_greeting

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

# opencode
fish_add_path /home/snow/.opencode/bin
alias mount-hdd="sudo /usr/local/bin/mount-hdd"
alias umount-hdd="sudo /usr/local/bin/umount-hdd"
alias mount-hdd="sudo /usr/local/bin/mount-hdd"
alias umount-hdd="sudo /usr/local/bin/umount-hdd"

# pnpm
set -gx PNPM_HOME "/home/snow/.local/share/pnpm"
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end
