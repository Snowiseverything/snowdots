function ww-reload
    pkill -f wall-watcher.sh
    # Use disown to let the shell exit while the watcher runs
    sh ~/Dotfiles/matugen/.local/bin/wall-watcher.sh > /dev/null 2>&1 &
    disown
    echo "󰈺 Watcher restarted and detached!"
end
