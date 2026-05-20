# SnowDots Setup

## Overview

Single `~/Dotfiles` repo for both Freezer (desktop) and SnowPi (RPi4).
Configs use `~/Dotfiles/` paths. Machine-specific logic via hostname detection.

```
~/
├── Dotfiles/          ← This repo (same path on both machines)
│   ├── scripts/
│   ├── fish/
│   ├── hypr/          ← Freezer-only (Hyprland)
│   └── ...
```

## How It Works

1. Both machines use `~/Dotfiles`
2. `dotsync` detects `freezer` or `snowpi` and pushes to correct GitLab
3. Freezer → `sn0wman/snowdots.git` (GitLab) + `Snowiseverything/snowdots.git` (GitHub)
4. SnowPi → `sn0wman/snowpi-dotfiles.git` (GitLab only)

## Setup

```bash
bash ~/Dotfiles/scripts/setup-freezer.sh   # on Freezer
bash ~/Dotfiles/scripts/setup-snowpi.sh    # on SnowPi
```

## Syncing

```bash
dotsync
```

## Remotes

```bash
# Freezer
gitlab→git@gitlab.com:sn0wman/snowdots.git
github→git@github.com:Snowiseverything/snowdots.git

# SnowPi
origin→git@gitlab.com:sn0wman/snowpi-dotfiles.git
```
