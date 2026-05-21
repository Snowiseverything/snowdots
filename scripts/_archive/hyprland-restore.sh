#!/bin/bash
# Restore hyprland.conf from backups
# Priority: 1) git HEAD  2) .main backup  3) .save backup

RESTORED=false

if [ -f ~/Dotfiles/hypr/hyprland.conf ] && [ "$(wc -l < ~/Dotfiles/hypr/hyprland.conf)" -gt 100 ]; then
    echo "Dotfiles hyprland.conf looks OK ($(wc -l < ~/Dotfiles/hypr/hyprland.conf) lines)"
    exit 0
fi

echo "Hyprland config broken! Restoring..."

# Try git
if git -C ~/Dotfiles show HEAD:hypr/hyprland.conf 2>/dev/null | wc -l | xargs test 100 -le; then
    git -C ~/Dotfiles checkout HEAD -- hypr/hyprland.conf
    echo "Restored from git HEAD"
    RESTORED=true
fi

# Try .main backup
if [ "$RESTORED" = false ] && [ -f /mnt/backups/System-Mirror/home-dots/hypr/hyprland.conf.main ]; then
    cp /mnt/backups/System-Mirror/home-dots/hypr/hyprland.conf.main ~/Dotfiles/hypr/hyprland.conf
    echo "Restored from /mnt/backups/main"
    RESTORED=true
fi

# Try .save
if [ "$RESTORED" = false ] && [ -f ~/Dotfiles/hypr/hyprland.conf.save ]; then
    cp ~/Dotfiles/hypr/hyprland.conf.save ~/Dotfiles/hypr/hyprland.conf
    echo "Restored from .save"
    RESTORED=true
fi

if [ "$RESTORED" = true ]; then
    hyprctl reload
    echo "Hyprland reloaded. Run 'dotsync' to push to gitlab."
else
    echo "No backup found! Check /mnt/backups/ manually."
    exit 1
fi
