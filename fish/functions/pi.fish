function pi
    # Wrapper: on interactive TUI launches, check for a newer Pi release and
    # offer to update before starting. Everything else passes through untouched.

    # Classify as a TUI launch (bare, resume, continue, fork, or named session)
    set -l is_tui 0
    if test (count $argv) -eq 0
        set is_tui 1
    else
        switch $argv[1]
            case -r --resume -c --continue --fork -f --session -s -n --name
                set is_tui 1
        end
    end

    if test $is_tui -eq 1 -a (isatty stdin)
        # Quick, silent version check (4s cap); skip on any failure
        set -l latest (curl -s --max-time 4 https://pi.dev/api/latest-version 2>/dev/null \
            | string match -r '"version":"[^"]+"' | string replace -r '.*:"([^"]+)".*' '$1')
        set -l current (command pi --version 2>/dev/null | string trim)
        if test -n "$latest" -a "$latest" != "$current"
            echo (set_color yellow)"Pi update available: $current → $latest"(set_color normal)
            read -l -P 'Update now? [Y/n] ' ans
            switch $ans
                case '' y Y yes YES
                    command pi update
            end
        end
    end

    command pi $argv
end
