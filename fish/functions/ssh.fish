########################################################################
##  SnowDots — SnowSsh                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

function ssh
    if string match -q "*snowpi*" -- $argv; or string match -q "*192.168.1.35*" -- $argv
        kitty --detach sh -c "exec ssh -t $argv fish"
    else
        command ssh $argv
    end
end
