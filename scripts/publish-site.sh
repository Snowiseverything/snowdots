#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../Notes/RootSite"

msg="${1:-site: update}"

./build-site.py
git add -A
git commit -m "$msg"
git push origin main

echo "Published at https://sn0wmann1.github.io/"
