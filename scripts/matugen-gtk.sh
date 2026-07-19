#!/bin/bash
# Generate GTK colors.css from matugen cache for material-gnome-theme

COLORS_FILE="$HOME/.cache/skwd-wall/colors.json"
THEME_DIR="$HOME/.themes/Material-Gnome"

[ ! -f "$COLORS_FILE" ] && exit 0
[ ! -d "$THEME_DIR" ] && exit 0

python3 -c "
import json, os

theme_dir = os.path.expanduser('$THEME_DIR')
colors_file = os.path.expanduser('$COLORS_FILE')

with open(colors_file) as f:
    c = json.load(f)

# Map skwd-wall keys to material-gnome @define-color names
def g(k, default='#000000'):
    v = c.get(k, c.get(k.replace('_', ''), ''))
    return str(v) if v and v != '' else default

colors_css = f'''/*
* GTK Colors
* Generated with Matugen
*/

@define-color primary {g('primary')};
@define-color on_primary {g('primaryText')};
@define-color primary_container {g('primaryContainer')};
@define-color on_primary_container {g('primaryContainerText')};
@define-color inverse_primary {g('primary')};
@define-color primary_fixed {g('primary')};
@define-color primary_fixed_dim {g('primaryContainer')};
@define-color on_primary_fixed {g('primaryText')};
@define-color on_primary_fixed_variant {g('primaryText')};

@define-color secondary {g('secondary')};
@define-color on_secondary {g('secondaryText')};
@define-color secondary_container {g('secondaryContainer')};
@define-color on_secondary_container {g('secondaryContainerText')};
@define-color secondary_fixed {g('secondary')};
@define-color secondary_fixed_dim {g('secondaryContainer')};
@define-color on_secondary_fixed {g('secondaryText')};
@define-color on_secondary_fixed_variant {g('secondaryText')};

@define-color tertiary {g('tertiary')};
@define-color on_tertiary {g('tertiaryText')};
@define-color tertiary_container {g('tertiaryContainer')};
@define-color on_tertiary_container {g('tertiaryContainerText')};
@define-color tertiary_fixed {g('tertiary')};
@define-color tertiary_fixed_dim {g('tertiaryContainer')};
@define-color on_tertiary_fixed {g('tertiaryText')};
@define-color on_tertiary_fixed_variant {g('tertiaryText')};

@define-color error {g('error')};
@define-color on_error {g('errorText')};
@define-color error_container {g('errorContainer')};
@define-color on_error_container {g('errorContainerText')};

@define-color surface_dim {g('surface')};
@define-color surface {g('surface')};
@define-color surface_tint {g('primary')};
@define-color surface_bright {g('surface')};
@define-color surface_container_lowest {g('background')};
@define-color surface_container_low {g('surfaceContainer')};
@define-color surface_container {g('surfaceContainer')};
@define-color surface_container_high {g('surfaceContainer')};
@define-color surface_container_highest {g('surfaceContainer')};
@define-color surface_variant {g('surfaceVariant')};
@define-color on_surface {g('surfaceText')};
@define-color on_surface_variant {g('surfaceVariantText')};

@define-color outline {g('outline')};
@define-color outline_variant {g('surfaceVariant')};

@define-color inverse_surface {g('surfaceText')};
@define-color inverse_on_surface {g('surface')};

@define-color background {g('background')};
@define-color on_background {g('backgroundText')};

@define-color shadow {g('shadow')};
@define-color scrim #000000;
@define-color source_color {g('primary')};
'''

for ver in ['3.0', '4.0']:
    path = f'{theme_dir}/gtk-{ver}/colors.css'
    with open(path, 'w') as f:
        f.write(colors_css)
    print(f'Updated {path}')
" 2>/dev/null
