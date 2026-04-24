function ww-reload
    # 1. Check if the daemon is already running
    if pgrep -x "skwd-daemon" > /dev/null
        if test -f ~/.cache/skwd-wall/wallpaper/current.json
            set -l last_wall (cat ~/.cache/skwd-wall/wallpaper/current.json | jq -r '.path')

            awww img "$last_wall"
            skwd wall set "$last_wall"
            # Pass the variable directly to avoid race conditions
            bash ~/.local/bin/wall-sync.sh "$last_wall"
        end
    else
        # 2. Heavy restart
        rm -rf /run/user/(id -u)/skwd/
        awww-daemon &
        sleep 0.8 # Slightly longer sleep for stability
        skwd-daemon &
        sleep 0.5
        
        if test -f ~/.cache/skwd-wall/wallpaper/current.json
            set -l last_wall (cat ~/.cache/skwd-wall/wallpaper/current.json | jq -r '.path')
            awww img "$last_wall"
            skwd wall set "$last_wall"
            bash ~/.local/bin/wall-sync.sh "$last_wall"
        end
        
        # Kill old watcher if exists before starting new one
        pkill -f wall-watcher.sh
        sh /home/snow/.local/bin/wall-watcher.sh &
    end

    hyprctl notify 1 2000 "rgb(8839ef)" "System Sync Complete"
end
