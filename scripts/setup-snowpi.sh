#!/bin/bash
# --------------------------------------------------------------------------
# Dotfiles Setup Script for SnowPi
# --------------------------------------------------------------------------

echo "❄️  Setting up Dotfiles for SnowPi..."

# 1. Ensure Dotfiles directory exists
if [ ! -d "$HOME/Dotfiles" ]; then
    echo "❌ Dotfiles not found at $HOME/Dotfiles"
    exit 1
fi
echo "✓ Dotfiles at $HOME/Dotfiles"

# 2. Create .local/bin symlinks
mkdir -p ~/.local/bin
cd ~/.local/bin

for script in "$HOME/Dotfiles/scripts"/*.sh; do
    name=$(basename "$script")
    if [ -f "$script" ] && [ ! -L "$name" ]; then
        ln -sf "$script" "$name"
    fi
done
ln -sf "$HOME/Dotfiles/scripts/dotsync" dotsync
echo "✓ Linked scripts to ~/.local/bin"

# 3. Add cargo bin to PATH if not already
if ! grep -q "\.cargo/bin" ~/.config/fish/config.fish 2>/dev/null; then
    mkdir -p ~/.config/fish
    echo "fish_add_path ~/.cargo/bin" >> ~/.config/fish/config.fish
    echo "✓ Added ~/.cargo/bin to fish PATH"
fi

# 4. Setup Git remotes
cd ~/Dotfiles
git remote add gitlab git@gitlab.com:sn0wman/dotfiles.git 2>/dev/null || true

# 5. Add SSH keys to known_hosts
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add freezer if not exists
if ! grep -q "freezer" ~/.ssh/known_hosts 2>/dev/null; then
    ssh-keyscan -H 192.168.0.111 >> ~/.ssh/known_hosts 2>/dev/null
    ssh-keyscan -H freezer >> ~/.ssh/known_hosts 2>/dev/null
    echo "✓ Added Freezer to known_hosts"
fi

# Add GitLab if not exists
if ! grep -q "gitlab.com" ~/.ssh/known_hosts 2>/dev/null; then
    ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts 2>/dev/null
    echo "✓ Added GitLab to known_hosts"
fi

echo ""
echo "✅ Setup complete! Run 'source ~/.config/fish/config.fish' to reload shell."