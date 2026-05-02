########################################################################
##  SnowDots — Snow                             Version: v1.0.0    ##
##  Last Edited: 2026-04-29                                           ##
########################################################################

#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
