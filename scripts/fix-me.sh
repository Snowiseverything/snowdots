cat << 'EOF' > ~/fix-me.sh
#!/bin/bash
# 1. Create a safety snapshot
snapper -c root create --description "Before fix-me update"

# 2. Speed up mirrors
echo "🚀 Rating mirrors..."
sudo cachyos-rate-mirrors

# 3. Update everything
echo "📦 Updating System and AUR..."
yay -Syu --noconfirm

# 4. Clean cache to save space
echo "💾 Cleaning cache..."
sudo pacman -Sc --noconfirm

# 5. Sync Limine (Crucial for CachyOS)
echo "🔧 Syncing Limine..."
sudo limine-mkinitcpio

# 6. Remove Orphans safely
ORPHANS=$(pacman -Qtdq)
if [ -n "$ORPHANS" ]; then
    echo "🧹 Removing orphans: $ORPHANS"
    sudo pacman -Rs $ORPHANS --noconfirm
else
    echo "✅ No orphans found."
fi

echo "✨ System is now Solid!"
EOF

chmod +x ~/fix-me.sh
