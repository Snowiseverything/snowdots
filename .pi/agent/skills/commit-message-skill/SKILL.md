---
name: snow-commit
description: 'Generate Tailscale/Go style commit messages from git diffs. Follows the area: imperative-verb format. Supports multi-remote push workflow. Use when asked to "commit", "write a commit message", "generate a commit", or "what should I commit this as".'
---

# Snow Commit

Generates commit messages in [Tailscale/Go style](https://github.com/tailscale/tailscale/blob/main/docs/commit-messages.md) — `area: imperative verb description`. Focuses on why a change was made, not just what files were touched.

## Rules

### Subject line

```
area: imperative verb description
```

- `area` is the primary directory or package affected (no trailing `/`)
- Verb in imperative mood: `add fix remove rewrite` not `adding fixes adds`
- Lowercase after the colon and space
- No trailing period
- Keep under 72 characters
- Area replaces the type — no Conventional Commits prefix (`feat:`, `fix:`)

### Body

- Blank line after subject
- Explain **why** the change was made, not how
- Describe the problem that existed before
- Wrap at 76 characters
- Reference issues: `Fixes #NNN`, `Updates #NNN`

### Multi-area changes

```
scripts/{govee,rgb}: unify fade timing
scripts,wlogout: update color palette
```

### Examples

| Good | Bad |
| ------ | ----- |
| `scripts: fix connection leak in sync loop` | `fix: connection leak` (Conventional Commits) |
| `hypr: update animation config for 0.56+` | `scripts: fixed the leak` (past tense) |
| `quickshell: add scroll support to sidebar` | `sidebar: add scroll` (wrong area) |
| `docs: document multi-remote push workflow` | `docs: Document multi-remote push.` (capitalized, trailing period) |

## Workflow

### Standard repos

```sh
git diff --staged          # see what will be committed
git commit -m "area: description"
git push origin main
```

### Multi-remote workflow

Some repos push to multiple remotes (e.g. public, private, backup). Verify all three received the commit:

```sh
git push remote1 main
git push remote2 main
git push remote3 main

# Verify
for remote in remote1 remote2 remote3; do
    echo "$remote: $(git ls-remote $remote main | cut -c1-7)"
done
```

## Before Committing

### Test your changes

- **Never commit untested changes.**
- Reload/restart the affected service and verify the change works.
- For config files: reload and check for errors.
- For scripts: run directly and confirm output.
- For compiled languages: verify build succeeds.

### Scan for private info

Before pushing to public remotes, check for:

- IP addresses (private ranges, VPN IPs)
- API tokens, passwords, secrets
- Network topology details
- User home directory paths

Private remotes can have full configs.

## Context Tools

- **Multi-command research** → `ctx_batch_execute(commands: [...], queries: [...])`
- **Process files without context bloat** → `ctx_execute_file(path, code)`
- **Run code over output** → `ctx_execute(language, code)`
- **Search indexed knowledge** → `ctx_search(queries: [...])`
- **Index docs for recall** → `ctx_index(content/path, source)`
- **Fetch web pages** → `ctx_fetch_and_index(urls: [...])` then `ctx_search`
- **Prefer these over raw curl/wget** — keeps context window lean.
