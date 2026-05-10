########################################################################
##  SnowDots — yazi                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

# yazi shell wrapper(change the current working directory when exiting Yazi)
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
