#!/bin/bash
# --------------------------------------------------------------------------
# Dotfiles Setup Script for Freezer
# --------------------------------------------------------------------------

echo "❄️  Setting up Dotfiles..."

# 1. Ensure Dotfiles directory exists
if [ ! -d "$HOME/Dotfiles" ]; then
    echo "❌ Dotfiles not found at $HOME/Dotfiles"
    exit 1
fi
echo "✓ Dotfiles at $HOME/Dotfiles"

# 2. Create .config symlinks
mkdir -p ~/.config
cd ~/.config

declare -A configs=(
    ["fastfetch"]="$HOME/Dotfiles/fastfetch"
    ["fish"]="$HOME/Dotfiles/fish"
    ["kitty"]="$HOME/Dotfiles/kitty"
    ["starship.toml"]="$HOME/Dotfiles/starship/starship.toml"
)

for target in "${!configs[@]}"; do
    if [ -L "$target" ]; then
        rm "$target"
    fi
    ln -sf "${configs[$target]}" "$target"
    echo "✓ Linked ~/.config/$target"
done

# 3. Create hypr symlinks
mkdir -p ~/.config/hypr
ln -sf "$HOME/Dotfiles/hypr/hyprland.conf" ~/.config/hypr/
ln -sf "$HOME/Dotfiles/hypr/hypridle.conf" ~/.config/hypr/
echo "✓ Linked Hyprland config"

# 4. Create .local/bin symlinks
mkdir -p ~/.local/bin
cd ~/.local/bin

for script in "$HOME/Dotfiles/scripts"/*.sh; do
    name=$(basename "$script")
    if [ ! -L "$name" ]; then
        ln -sf "$script" "$name"
    fi
done
ln -sf "$HOME/Dotfiles/scripts/dotsync" dotsync
echo "✓ Linked scripts to ~/.local/bin"

# 5. Add cargo bin to PATH if not already
if ! grep -q "\.cargo/bin" ~/.config/fish/config.fish 2>/dev/null; then
    echo "fish_add_path ~/.cargo/bin" >> ~/.config/fish/config.fish
    echo "✓ Added ~/.cargo/bin to fish PATH"
fi

# 6. Add SSH keys to known_hosts
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add GitLab if not exists
if ! grep -q "gitlab.com" ~/.ssh/known_hosts 2>/dev/null; then
    ssh-keyscan -H gitlab.com >> ~/.ssh/known_hosts 2>/dev/null
    echo "✓ Added GitLab to known_hosts"
fi

echo ""
echo "✅ Setup complete! Run 'source ~/.config/fish/config.fish' to reload shell."