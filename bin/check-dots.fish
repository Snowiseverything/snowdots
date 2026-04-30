#!/usr/bin/env fish

if not set -q DOTS
    set -gx DOTS ~/Dotfiles
end

echo "❄️  Checking Dotfiles Integrity in $DOTS..."
echo "------------------------------------------------"
cd $DOTS

set untracked (git ls-files --others --exclude-standard)
set modified (git status --porcelain | string match -r '^ M|^M ')

if test -n "$untracked"
    echo "⚠️  UNTRACKED FILES FOUND:"
    for file in $untracked
        echo "  - $file"
    end
    echo ""
    echo "💡 Run 'dotsync' now to track and backup these files."
else if test -n "$modified"
    echo "📝 MODIFICATIONS FOUND (Uncommitted)"
    echo "💡 Run 'dotsync' to save your changes."
else
    echo "✅ Everything is tracked and up to date."
end

# Remote Check
git fetch snowpi >/dev/null 2>&1
set status_output (git status -uno)
if not string match -q "*Your branch is up to date*" "$status_output"
    echo "📡 Remote Status: Local and SnowPi are out of sync. Run 'dotsync'!"
end
