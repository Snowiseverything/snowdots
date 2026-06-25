# Commit Style

This repo uses [commit-message-skill](https://github.com/sn0wmann1/commit-message-skill) to generate conventional commit messages from staged changes.

## Format

```
<type>: <description>

<body>
```

Types are inferred heuristically from changed files:

- `feat` — only new files added
- `fix` — mix of added/modified changes (default fallback)
- `docs` — markdown/readme changes
- `test` — test file changes
- `chore` — config/package changes

Scope (directory of first changed file) is included only when auto-detected.

## Usage

```bash
# Commit staged changes with body
commit-message-skill --from-cached --body --commit

# Dotfiles mode (adds all, commits, pushes to all remotes)
commit-message-skill --dotfiles "description of changes"
```

## Remotes

- `gitlab` — private cloud (primary)
- `snowpi` — LAN/Tailscale peer (secondary)
- `github` — public sanitized mirror (via publish-public.sh)

## Reference

Profile repo: `type: description` (no scope)
Dotfiles repo: auto-detected scope from file paths
