#!/bin/bash
# toofan-theme.sh — generate matugen theme for toofan and rebuild from source
set -euo pipefail

TOOFAN_SRC="${TOOFAN_SRC:-$HOME/.local/src/toofan}"
TEMPLATE="$HOME/Dotfiles/matugen/templates/toofan.go"
OUTPUT="$TOOFAN_SRC/internal/theme/matugen.go"
TOOFAN_BIN="$HOME/.local/bin/toofan"
COLOR_CACHE="$HOME/.cache/skwd-wall/colors.json"

log() { echo "[toofan-theme] $*"; }

# Ensure source is cloned
if [ ! -d "$TOOFAN_SRC" ]; then
    log "Cloning toofan source..."
    mkdir -p "$(dirname "$TOOFAN_SRC")"
    git clone https://github.com/vyrx-dev/toofan.git "$TOOFAN_SRC"
fi

# Check if matugen cached output exists (template already rendered)
CACHED="$HOME/.cache/skwd-wall/toofan.go"
if [ -f "$CACHED" ]; then
    cp "$CACHED" "$OUTPUT"
    log "Copied rendered theme from cache"
elif [ -f "$COLOR_CACHE" ]; then
    # Render template inline using cached colors
    python3 << PYEOF
import json, re

with open("$TEMPLATE") as f:
    template = f.read()

with open("$COLOR_CACHE") as f:
    c = json.load(f)

color_map = {
    "{{colors.surface.default.hex}}": c["surface"],
    "{{colors.on_surface_variant.default.hex}}": c.get("surfaceVariantText", c["foreground"]),
    "{{colors.on_surface.default.hex}}": c.get("surfaceText", c["foreground"]),
    "{{colors.error.default.hex}}": c["error"],
    "{{colors.primary.default.hex}}": c["primary"],
    "{{colors.tertiary.default.hex}}": c["tertiary"],
}

for placeholder, value in color_map.items():
    template = template.replace(placeholder, value)

with open("$OUTPUT", "w") as f:
    f.write(template)

print("Rendered matugen.go from cached colors")
PYEOF
else
    log "No colors cache found — copying unrendered template (run matugen first)"
    cp "$TEMPLATE" "$OUTPUT"
fi

# Ensure Matugen is registered in theme.go
if ! grep -q "Matugen" "$TOOFAN_SRC/internal/theme/theme.go" 2>/dev/null; then
    log "Registering Matugen theme..."
    sed -i 's/var All = \[\]Palette{TokyoNight/var All = []Palette{Matugen, TokyoNight/' \
        "$TOOFAN_SRC/internal/theme/theme.go"
    sed -i 's/var Current = TokyoNight/var Current = Matugen/' \
        "$TOOFAN_SRC/internal/theme/theme.go"
    sed -i 's/return TokyoNight/return Matugen/' \
        "$TOOFAN_SRC/internal/theme/theme.go"
fi

# Rebuild
log "Rebuilding toofan..."
cd "$TOOFAN_SRC"
go build -o "$TOOFAN_BIN" .

# Update config to use matugen theme
CONFIG="$HOME/.config/toofan/config.json"
if [ -f "$CONFIG" ]; then
    python3 -c "
import json
with open('$CONFIG') as f:
    cfg = json.load(f)
cfg['theme'] = 'matugen'
with open('$CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
"
    log "Set theme to matugen in config"
fi

log "Done! Toofan rebuilt with matugen theme."
