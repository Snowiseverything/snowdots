#!/usr/bin/env bash
# --------------------------------------------------------------------------
# projects-sync.sh — Seamless sync between /home/snow/Projects and Obsidian vault
# --------------------------------------------------------------------------
# Repos → Vault: copy project docs into Obsidian Vault/Projects for FNS sync
# Vault → Repos: copy edited project docs back to repos after phone edits
# Vault-only notes: preserved, never overwritten
# --------------------------------------------------------------------------

set -euo pipefail

REPOS="/home/snow/Projects"
VAULT="/home/snow/Obsidian Vault/Projects"
VAULT_ONLY=(
	"Borsay Qallat/map-pins.md"
	"Delivery & Fleet Management System (Project Blueprint).md"
)

# Projects to sync: source_dir:vault_name
SYNC_MAP=(
	"Borsay Qallat/docs:Borsay Qallat"
	"viymess:Viymess"
	"madlions-configurator:madlions-configurator"
)

# Directories to keep in repo only; do not copy to vault or sync via FNS
EXCLUDE_DIRS=(
	"viymess/apps"
	"viymess/node_modules"
)

log() { echo "[projects-sync] $*"; }

# Ensure vault dirs exist
mkdir -p "$VAULT"

# Cleanup old duplicate files in vault before syncing
for entry in "${SYNC_MAP[@]}"; do
	dst_name="${entry##*:}"
	case "$dst_name" in
	"Borsay Qallat")
		rm -f "$VAULT/Borsay Qallat/Borsay Qallat Progress.md"
		rm -f "$VAULT/Borsay Qallat/Borsay Qallat Project.md"
		rm -f "$VAULT/Borsay Qallat Progress.md"
		rm -f "$VAULT/Borsay Qallat Project.md"
		;;
	"Viymess")
		rm -f "$VAULT/Viymess/Viymess e-Store Web Project.md"
		rm -f "$VAULT/Viymess/Viymess Status & Roadmap.md"
		rm -f "$VAULT/Viymess/Viymess Progress.md.old"
		rm -f "$VAULT/Viymess/Viymess e-commerce web app.md.old"
		rm -rf "$VAULT/Viymess/apps" "$VAULT/Viymess/node_modules"
		;;
	esac
done

# Copy repo docs → vault, excluding code trees
for entry in "${SYNC_MAP[@]}"; do
	src_rel="${entry%%:*}"
	dst_name="${entry##*:}"
	src="$REPOS/$src_rel"
	dst="$VAULT/$dst_name"

	if [ ! -d "$src" ]; then
		log "SKIP missing source: $src"
		continue
	fi

	mkdir -p "$dst"

	# Copy top-level markdown files from repo to vault
	find "$src" -maxdepth 1 -type f -name '*.md' -print0 | while IFS= read -r -d '' f; do
		bn="$(basename "$f")"
		# Skip vault-only files (loop — array-in-case-pattern never matched)
		skip=false
		for vo in "${VAULT_ONLY[@]}"; do
			if [ "$dst_name/$bn" = "$vo" ]; then skip=true; break; fi
		done
		if [ "$skip" = true ]; then continue; fi
		cp -f "$f" "$dst/$bn"
	done

	# Also copy nested markdown files, excluding code-only directories
	find "$src" -mindepth 2 -type f -name '*.md' -print0 | while IFS= read -r -d '' f; do
		rel="${f#$src/}"
		skip=false
		for ex in "${EXCLUDE_DIRS[@]}"; do
			if [[ "$rel" == "$ex"/* ]]; then
				skip=true
				break
			fi
		done
		if [ "$skip" = true ]; then
			continue
		fi
		dst_file="$dst/$rel"
		mkdir -p "$(dirname "$dst_file")"
		cp -f "$f" "$dst_file"
	done

done

# Copy vault-only notes back if they were edited on phone
for note in "${VAULT_ONLY[@]}"; do
	src="$VAULT/$note"
	dst="$REPOS/$note"
	if [ -f "$src" ]; then
		mkdir -p "$(dirname "$dst")"
		cp -f "$src" "$dst"
	fi
done

log "sync complete"
