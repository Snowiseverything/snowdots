#!/bin/bash
# setup-oc-sync.sh — Symlink shared OC configs into ~/.opencode/

DOTFILES_DIR="$HOME/Dotfiles"
OC_DIR="$HOME/.opencode"
SHARED_DIR="$DOTFILES_DIR/.opencode"

[ ! -d "$SHARED_DIR" ] && echo "No shared OC config at $SHARED_DIR" && exit 1

for f in AGENTS.md MEMORY.md SOUL.md opencode.json; do
    if [ -f "$OC_DIR/$f" ] && [ ! -L "$OC_DIR/$f" ]; then
        mv "$OC_DIR/$f" "$OC_DIR/$f.bak"
        echo "backed up $OC_DIR/$f → $OC_DIR/$f.bak"
    fi
    ln -sf "$SHARED_DIR/$f" "$OC_DIR/$f"
done

if [ -d "$OC_DIR/skills" ] && [ ! -L "$OC_DIR/skills" ]; then
    mv "$OC_DIR/skills" "$OC_DIR/skills.bak"
    echo "backed up $OC_DIR/skills → $OC_DIR/skills.bak"
fi
ln -sfn "$SHARED_DIR/skills" "$OC_DIR/skills"

echo "OC sync done → $OC_DIR now linked to $SHARED_DIR"
ls -la "$OC_DIR/AGENTS.md" "$OC_DIR/MEMORY.md" "$OC_DIR/SOUL.md" "$OC_DIR/opencode.json" "$OC_DIR/skills"
