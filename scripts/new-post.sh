#!/usr/bin/env bash
set -euo pipefail

BLOG_DIR="$(dirname "$0")/../Notes/Blog"
POSTS_DIR="$BLOG_DIR/src/content/blog"

title="${1:-}"
[ -z "$title" ] && echo "Usage: new-post.sh \"Post Title\"" && exit 1

slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
date=$(date +%Y-%m-%d)
file="$POSTS_DIR/$slug.md"

[ -f "$file" ] && echo "Exists: $file" && exit 1

cat > "$file" <<EOF
---
title: $title
description: 
pubDate: $date
tags: []
---

EOF

echo "Created $file"
