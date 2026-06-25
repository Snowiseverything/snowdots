function tscheck --wraps='~/Dotfiles/scripts/ts-check.sh' --description 'alias tscheck=~/Dotfiles/scripts/ts-check.sh'
  if test (hostname) = snowpi
    ~/Dotfiles/scripts/ts-check.sh $argv
  else
    echo "tscheck: only available on SnowPi"
  end
end
