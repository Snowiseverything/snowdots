# Snow Memory

OpenCode memory, soul, config, and agents for Freezer + Snowpi.

## Contents

```
MEMORY.md      — Session history, decisions, system context
AGENTS.md      — System prompt context (paths, constraints, preferences)
opencode.json  — OpenCode config (permissions, plugins, theme)
agents/        — 10 subagent definitions (health, docker, sync, etc.)
```

## How It Works

Shared across two machines via `oc-sync.sh`:
- **Freezer** — main workstation (CachyOS, Hyprland)
- **Snowpi** — backup Pi (DietPi, Tailscale)

Changes on either machine get merged bidirectionally.

## Repos

| Remote | URL |
|--------|-----|
| GitHub | `Snowiseverything/snow-memory` |
| GitLab | `sn0wman/snow-memory` |

Push to either for backup. Oc-sync handles machine-to-machine sync.

## File Details

- **MEMORY.md** — Append-only session log. Captures decisions, bugs fixed, config changes. Read by OpenCode at session start.
- **AGENTS.md** — Environment context injected into every OpenCode session. Hardware paths, constraints (no sudo), service commands.
- **opencode.json** — Granular bash permissions (safe cmds auto-allow). Plugin list. Theme path.
- **agents/** — One `.md` per subagent with purpose + tool instructions. Used by OpenCode for task routing.

## Quick Save

```fish
~/bin/mem "thing to remember"
```

Appends timestamped note to MEMORY.md.

## Sync Flow

```
Freezer edits MEMORY.md
  → oc-sync.sh (30min timer)
    → rsyncs .opencode/ + .agents/ to Snowpi
    → bidirectional SQLite session merge
      → both machines have same state
```

Manual: `bash ~/Dotfiles/scripts/oc-sync.sh`
