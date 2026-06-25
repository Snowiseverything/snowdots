#!/bin/bash
# import-notesnook.sh — Import Notesnook markdown export into Obsidian vault
# Usage: ./import-notesnook.sh <path/to/notesnook-export.zip>

set -euo pipefail

VAULT="$HOME/Notes"
EXPORT="$1"

if [ -z "$EXPORT" ] || [ ! -f "$EXPORT" ]; then
    echo "Usage: $0 <path/to/notesnook-export.zip>"
    exit 1
fi

TMP=$(mktemp -d)
unzip -q "$EXPORT" -d "$TMP" || { echo "Failed to extract"; exit 1; }

COUNT=0
while IFS= read -r -d '' f; do
    BASENAME=$(basename "$f")
    [ -f "$VAULT/$BASENAME" ] && continue

    TITLE=$(head -1 "$f" | sed 's/^# //' | tr -d '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "$BASENAME")

    CONTENT=$(sed '1{/^# /d}' "$f")
    {
        echo "---"
        echo "title: \"$TITLE\""
        echo "source: notesnook"
        echo "---"
        echo ""
        [ -z "$CONTENT" ] && echo "# $TITLE"
        [ -n "$CONTENT" ] && echo "$CONTENT"
    } > "$VAULT/$BASENAME"

    COUNT=$((COUNT + 1))
    echo "  Imported: $BASENAME"
done < <(find "$TMP" -name '*.md' -type f -print0)

rm -rf "$TMP"
echo "Imported $COUNT notes to $VAULT"
