########################################################################
##  SnowDots — aliases                             Version: v1.0.0    ##
##  Last Edited: 2026-04-30                                           ##
########################################################################

# ┌─────────┐
# │ Aliases │
# └─────────┘

#General
alias ls='eza -1 --icons=auto'
alias l='eza -lh --icons=auto'
alias zed='zeditor'
abbr -a c clear
abbr -a la 'ls -a'
alias ll='eza -lha --icons=auto --sort=name --group-directories-first'
abbr -a ld 'eza -lhD --icons=auto'
abbr -a lt 'eza --icons=auto --tree'
abbr -a ltt 'eza --tree --level=2 --long --icons --git'
abbr -a lta 'lt -a'
# abbr -a bash 'source ~/.bashrc'
abbr -a bfile 'nvim ~/.bashrc'
abbr -a ffile 'nvim ~/.config/fish/config.fish'
# abbr -a fish 'source ~/.config/fish/config.fish'
abbr -a xx tmux

# change your default USER shell
alias tobash="chsh $USER -s /usr/bin/bash && echo 'Log out and log back in for change to take effect.'"
alias tozsh="chsh $USER -s /usr/bin/zsh && echo 'Log out and log back in for change to take effect.'"
alias tofish="chsh $USER -s /usr/bin/fish && echo 'Log out and log back in for change to take effect.'"

#When was the Last update
alias last-updated='grep -i "full system upgrade" /var/log/pacman.log | tail -n 1'

# Check cache size
abbr -a cache 'du -sh /var/cache/pacman/pkg .cache/yay'

#to open ani cli
abbr -a ac ani-cli

# AVA Media live stream
abbr -a ava '/home/snow/scripts/ava-media-stream.sh'
abbr -a ava-toggle '/home/snow/scripts/ava-media-control.sh toggle'
abbr -a ava-back '/home/snow/scripts/ava-media-control.sh back'
abbr -a ava-live '/home/snow/scripts/ava-media-control.sh live'

#modified commands
abbr -a cp 'cp -i'
abbr -a mv 'mv -i'
abbr -a mkdir 'mkdir -p'
abbr -a ping 'ping -c 10'
abbr -a yayf "yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# File finding
abbr -a ffind 'find . -type f -name'
abbr -a fd 'find . -type d -name'
abbr -a fdh 'fd --hidden'

# Search files in the current folder
abbr -a f "find . | grep "

#Life Easy
# # alias cd='z'  # install zoxide to enable smart cd  # install zoxide to enable smart cd
abbr -a vim nvim
abbr -a nd 'npm run dev'
abbr -a n nvim
abbr -a open 'nautilus .'
abbr -a zz yazi
abbr -a lg lazygit
abbr -a x exit
abbr -a h "history | grep "
abbr -a kt 'kitten themes'
abbr -a g gemini
abbr -a d docker
abbr -a rip "yt-dlp -x --audio-format=\"mp3\""
abbr -a mp 'makepkg -si'
abbr -a chx 'chmod +x'
abbr -a tmuxk 'tmux kill-session'
abbr -a nb 'nvim ~/.config/hypr/bindings.conf'

# bigger font in tty and regular font in tty
abbr -a bigfont "setfont ter-132b"
abbr -a regfont "setfont default8x16"

# Some useful aliases
abbr -a update 'sudo pacman -Syu'
abbr -a pwreset 'faillock --reset --user vyrx'
abbr -a pg 'ping -c 10 google.com'

# Automatically do an ls after each cd, z, or zoxide
abbr -a cleanup 'sudo pacman -Rns $(pacman -Qdtq)'
abbr -a showpkg 'pacman -Qi' # Show package info
abbr -a mirrorfix 'sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist' # Fix mirrors
abbr -a pacclean 'sudo paccache -r' # Clean all but latest 3 versions
abbr -a paccleanall 'sudo paccache -r -c /var/cache/pacman/pkg -u' # Clean all cached packages
abbr -a pacckeep 'sudo paccache -k 3' # Keep latest 3 versions, remove rest
abbr -a cleanc 'sudo pacman -Sc && yay -Sc'
abbr -a folders 'du -h --max-depth=1'

# Git aliases
abbr -a gits 'git status'
abbr -a ghs 'streaker vyrx-dev'
abbr -a ghp 'gh repo create --public $(basename "$PWD") --source=. --description="desc" --push'

# Grub Update
abbr -a update-grub 'sudo grub-mkconfig -o /boot/grub/grub.cfg'

# Snapper
abbr -a slsr 'sudo snapper -c root list'
abbr -a slsh 'sudo snapper -c home list'
abbr -a sdu 'sudo btrfs filesystem du -s /.snapshots/*'
abbr -a sdelr 'sudo snapper -c root delete'
abbr -a sdelh 'sudo snapper -c home delete --sync' #eg  --sync 1 or 2-4
abbr -a sbdel 'sudo btrfs subvolume delete' #eg  sudo btrfs subvolume delete /.snapshots/5/snapshot
# ── SSH ────────────────────────────────────────
alias snowpi='ssh snow@100.83.33.67'

# ── SnowDots Scripts ───────────────────────────
# All scripts in PATH (~/Dotfiles/scripts + ~/.local/bin)
# Aliases strip .sh/.py for convenience + short names for long scripts
alias audit='snow-audit.sh'
alias health='health.sh'
alias wall-reset='wall-reset.sh'
alias wall-sync='wall-sync.sh'
alias rename-wall='rename-wallpapers.sh'
alias night-light='night-light.sh'
alias sun-sched='sun-schedule.sh'
alias snow-ctl='fuzzel-control.sh'
alias fix-me='fix-me.sh'
alias publish='publish-public.sh'
alias rgb='rgb-sync.sh'
alias fav='fav-wall.sh'
alias shot='shot-smart.sh'
alias snow='snow-help.sh'
alias steam='steam-launch.sh'
alias block='toggle-adult-block.sh'
alias mad68='mad68-rgb.py'
alias govee='govee-led.py'
alias launcher='app-launcher.sh'
alias wall='wall-sync.sh'
alias wall-r='wall-reset.sh'

function _scripts --description "List all SnowDots script aliases with descriptions"
    set -l b (set_color -o)
    set -l bl (set_color 2563eb)
    set -l d (set_color 555555)
    set -l g (set_color 4ade80)
    set -l c (set_color 22d3ee)
    set -l r (set_color normal)

    printf '%s\n' "  ╭──────────────────────────────────────────────────────────╮"
    printf '  │  %sSnowDots Scripts%s  %s(call by name or alias)%s               │\n' $b $r $d $r
    printf '%s\n' "  ├──────────────────────────────────────────────────────────┤"

    set -l entries \
        "audit|snow-audit.sh|System audit & health overview" \
        "health|health.sh|Quick health check" \
        "fix-me|fix-me.sh|Auto-fix common issues" \
        "snow|snow-help.sh|Show snowdots help menu" \
        "publish|publish-public.sh|Push rice-only mirror → GitHub" \
        "wall|wall-sync.sh|Sync wallpaper via matugen" \
        "wall-r|wall-reset.sh|Reset to last wallpaper" \
        "wall-reset|wall-reset.sh|Reset wallpaper" \
        "wall-sync|wall-sync.sh|Sync wallpaper colors" \
        "fav|fav-wall.sh|Set as favorite wallpaper" \
        "rename-wall|rename-wallpapers.sh|Bulk rename wallpapers" \
        "rgb|rgb-sync.sh|Sync all RGB to wallpaper accent" \
        "mad68|mad68-rgb.py|MAD68 HE keyboard RGB control" \
        "govee|govee-led.py|Govee LED strip (via HA)" \
        "night-light|night-light.sh|Toggle night light filter" \
        "sun-sched|sun-schedule.sh|Sunrise/sunset schedule" \
        "shot|shot-smart.sh|Smart screenshot (region/window)" \
        "steam|steam-launch.sh|Launch Steam with optimizations" \
        "block|toggle-adult-block.sh|Toggle adult content blocking" \
        "snow-ctl|fuzzel-control.sh|Control panel via fuzzel" \
        "launcher|app-launcher.sh|App launcher helper"
    for entry in $entries
        set -l parts (string split "|" $entry)
        printf '  │  %s%-12s%s %s%-24s%s %s\n' $bl $parts[1] $r $d $parts[2] $r $parts[3]
    end

    printf '%s\n' "  ╰──────────────────────────────────────────────────────────╯"
    printf '\n  %sUsage:%s  scripts | grep <keyword>   or   scripts | fzf\n' $g $r
end
# ── OpenCode ────────────────────────────────────
alias oc='opencode'
alias oc-sync='~/scripts/oc-sync.sh'
alias boot-sync='systemctl --user start boot-sync.service'
alias boot-log='journalctl --user -u boot-sync.service -n 30 --no-pager'
alias update-check='systemctl --user start weekly-update.service && journalctl --user -u weekly-update.service -n 50 --no-pager'
alias update-now='yay -Syu'
# refresh
