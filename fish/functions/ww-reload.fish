########################################################################
##  SnowDots — wwreload                             Version: v1.0.0    ##
##  Last Edited: 2026-04-30                                           ##
########################################################################

function ww-reload
    pkill -f wall-watcher.sh
    # Use disown to let the shell exit while the watcher runs
    sh ~/Dotfiles/matugen/.local/bin/wall-watcher.sh > /dev/null 2>&1 &
    disown
    echo "󰈺 Watcher restarted and detached!"
end
