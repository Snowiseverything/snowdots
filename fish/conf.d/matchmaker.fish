# Matchmaker key bindings for fish
# Ctrl+F: fuzzy search files
# Ctrl+R: fuzzy search files + directories

set -gx MM_CONFIG ~/.config/mm/config.toml

# Files search (Ctrl+F)
function __mm_files
    set -l items (fd -H --strip-cwd-prefix -t f 2>/dev/null)
    if test -n "$items"
        set -l selected (echo "$items" | ~/.cargo/bin/mm --config $MM_CONFIG)
        if test -n "$selected" -a -e "$selected"
            cd (dirname "$selected")
        end
    end
end

# Files + Directories combined (Ctrl+R)
function __mm_all
    set -l items (begin
        fd -H --strip-cwd-prefix -t f 2>/dev/null
        fd -H --strip-cwd-prefix -t d 2>/dev/null
    end)
    if test -n "$items"
        set -l selected (echo "$items" | ~/.cargo/bin/mm --config $MM_CONFIG)
        if test -n "$selected" -a -e "$selected"
            if test -d "$selected"
                cd "$selected"
            else
                cd (dirname "$selected")
            end
        end
    end
end

# Bind Ctrl+F to files search
bind \cf __mm_files

# Bind Ctrl+R to files+dirs search
bind \cr __mm_all

# Alt+C: directories only
function __mm_dirs
    set -l items (fd -H --strip-cwd-prefix -t d 2>/dev/null)
    if test -n "$items"
        set -l selected (echo "$items" | ~/.cargo/bin/mm --config $MM_CONFIG)
        if test -n "$selected"
            cd "$selected"
        end
    end
end
bind \ec __mm_dirs
