#!/usr/bin/env bash
# Injects matugen-generated LuaTools theme into themes.json

THEMES_JSON="$HOME/.local/share/Steam/steamui/LuaTools/themes/themes.json"
MATUGEN_THEME="$HOME/.cache/skwd-wall/luatools-colors.json"

[ ! -f "$MATUGEN_THEME" ] && exit 0
[ ! -f "$THEMES_JSON" ] && exit 0

TEMP=$(mktemp)
python3 -c "
import json
with open('$THEMES_JSON') as f:
    themes = json.load(f)
with open('$MATUGEN_THEME') as f:
    matugen = json.load(f)

# Remove old matugen entry
themes = [t for t in themes if t.get('value') != 'matugen']
# Add new matugen entry
themes.insert(0, matugen)

with open('$TEMP', 'w') as f:
    json.dump(themes, f, indent=2)
" && mv "$TEMP" "$THEMES_JSON"