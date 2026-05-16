# Preview helper for Alt+C (dir contents)
function fzf_preview_dir
    command eza -1a --color=always $argv 2>/dev/null
end

# Mode labels (brackets make label boundaries clear)
set -gx FZF_CTRL_T_OPTS "--prompt=[files]"
set -gx FZF_CTRL_R_OPTS "--prompt=[history] --reverse"
set -gx FZF_ALT_C_OPTS "--prompt=[dirs] --scheme=default --tiebreak=begin --preview=fzf_preview_dir --preview-window=right:50%"

# Alt+C: list subdirs + .. (go up), preview dir contents
set -gx FZF_ALT_C_COMMAND "
  command find . -mindepth 1 -maxdepth 5 -type d 2>/dev/null | sed 's|^\\./||'
  echo ..
"

fzf --fish | source
