########################################################################
##  SnowDots — ts                             Version: v1.0.0    ##
##  Last Edited: 2026-05-05                                           ##
########################################################################

function ts --wraps=tailscale --description 'alias ts=tailscale'
    tailscale $argv
end
