# Preview helper for Alt+C (dir contents)
function fzf_preview_dir
    command eza -1a --color=always $argv 2>/dev/null
end

# Mode labels (brackets make label boundaries clear)
set -gx FZF_CTRL_T_OPTS "--prompt=[files]"
set -gx FZF_CTRL_R_OPTS "--prompt=[history] --reverse"
set -gx FZF_ALT_C_OPTS "--prompt=[dirs] --scheme=default --tiebreak=begin --preview=fzf_preview_dir --preview-window=right:50%"

# Ignore noise dirs
set -gx FZF_DEFAULT_COMMAND "
  command find . -not -path './node_modules/*' -not -path './.git/*' -not -path './.cache/*' 2>/dev/null | sed 's|^\./||'
"
set -gx FZF_CTRL_T_COMMAND "
  command find . -not -path './node_modules/*' -not -path './.git/*' -not -path './.cache/*' -type f 2>/dev/null | sed 's|^\./||'
"

# Alt+C: list subdirs (incl hidden) + .. (go up), preview dir contents
set -gx FZF_ALT_C_COMMAND "
  command find . -mindepth 1 -maxdepth 5 -not -path './node_modules/*' -not -path './.git/*' -not -path './.cache/*' -type d 2>/dev/null | sed 's|^\./||'
  echo ..
"

if type -q fzf
    fzf --fish | source
end
