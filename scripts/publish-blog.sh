#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../Notes/Blog"

msg="${1:-publish: blog update}"

git add -A
git commit -m "$msg"
git push origin main

echo "Deployed at https://sn0wmann1.github.io/blog/"
