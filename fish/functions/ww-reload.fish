function ww-reload --wraps='killall wall-watcher.sh; sh ~/.local/bin/wall-watcher.sh &'
    # Kill every instance of the watcher, even if it's hiding under 'sh'
        pkill -f wall-watcher.sh
        # Wait a second for them to actually die
        sleep 0.5
        # Start the new one
        sh /home/snow/.local/bin/wall-watcher.sh &
end
