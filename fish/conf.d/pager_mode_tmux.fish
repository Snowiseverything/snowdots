########################################################################
##  SnowDots — SnowPagermodetmux                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

# Prevent pager mode in tmux sessions
if set -q TMUX
    set -x PAGER cat
end
