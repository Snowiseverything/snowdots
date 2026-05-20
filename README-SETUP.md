# Dotfiles Setup

## Overview

This repo is designed to work on both Freezer (main PC) and SnowPi (RPi4) using a symlink approach.

### Directory Structure

```
~/
├── Freezer-Dotfiles/  ← Actual files (this repo)
│   ├── scripts/
│   ├── fish/
│   ├── hypr/
│   └── ...
├── SnowPi-Dotfiles/   ← Separate repo for SnowPi
│   ├── scripts/
│   ├── fish/
│   └── ...
└── Dotfiles/           ← Symlink to current machine's actual repo
    └── (points to Freezer-Dotfiles on Freezer, SnowPi-Dotfiles on SnowPi)
```

## How It Works

1. All configs use `~/Dotfiles/` paths
2. On Freezer: `~/Dotfiles` → `~/Freezer-Dotfiles`
3. On SnowPi: `~/Dotfiles` → `~/SnowPi-Dotfiles`
4. Both repos share same structure, but machine-specific configs differ

## Setup

### Freezer
```bash
# Run setup script
bash ~/Freezer-Dotfiles/scripts/setup-freezer.sh

# Or manually:
ln -sf ~/Freezer-Dotfiles ~/Dotfiles
```

### SnowPi
```bash
# Run setup script
bash ~/SnowPi-Dotfiles/scripts/setup-snowpi.sh

# Or manually:
ln -sf ~/SnowPi-Dotfiles ~/Dotfiles
```

## Syncing

Use `dotsync` to push/pull from GitLab:
```bash
dotsync
```

## Adding New Configs

When adding new configs:
1. Add to this repo
2. Create symlinks in `~/.config/` or `~/.local/bin/`
3. Update setup script if needed

## Scripts

- `setup-freezer.sh` - Setup Freezer
- `setup-snowpi.sh` - Setup SnowPi  
- `dotsync` - Sync to GitLab
- `dot-mirror.sh` - Backup to external drive
- `snow-audit.sh` - System audit

## SSH Keys

- Add your public key to `ssh/authorized_keys` in this repo
- Push to GitLab, then pull on other machines
- Use same key for both Freezer and SnowPi access