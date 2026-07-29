---
name: commit-message-skill
description: 'Generate Tailscale/Go style commit messages. Run `commit-message-skill --dotfiles` to see diff, then `commit-message-skill --dotfiles "scripts: add foo feature"` to commit and push.'
---

# commit-message-skill

Tailscale/Go style commit messages, based on [tailscale/tailscale commit message guide](https://github.com/tailscale/tailscale/blob/main/docs/commit-messages.md).

## Rules

### Subject line

```
area: imperative verb description
```

- `area` is the primary file or directory affected (no trailing `/`)
- Verb in imperative mood: `add fix remove bump` not `adding adds added`
- Verb is lowercase after the colon and space
- No trailing period
- Keep under ~76 characters

### Body

- Blank line after subject
- Wrap at ~76 characters
- Explain what and why, not how
- No Markdown
- End with `Fixes #NNN` or `Updates #NNN` if tracking an issue

### Examples

| Good                                            | Notes                          |
| ----------------------------------------------- | ------------------------------ |
| `scripts: fix memory leak in rgb-sync`          | area + imperative verb         |
| `hypr: update cursor theme config`              |                                |
| `scripts/{govee,openrgb}: rewrite BLE protocol` | {a,b} for multiple subpackages |
| `scripts,docs: update README with new commands` | two top-level areas            |

| Bad                            | Notes                           |
| ------------------------------ | ------------------------------- |
| `freezer: fix green cursor`    | BAD: hostname, not area         |
| `scripts: fixed memory leak`   | BAD: past tense                 |
| `scripts: fixing memory leak`  | BAD: -ing verb                  |
| `scripts: Fix memory leak`     | BAD: capitalized verb           |
| `fix: memory leak in rgb-sync` | BAD: conventional commit prefix |
| `scripts: fix memory leak.`    | BAD: trailing period            |

## Dotfiles mode

```sh
commit-message-skill --dotfiles                        # show diff summary
commit-message-skill --dotfiles "scripts: add foo feature"
```

Push targets: gitlab (primary), snowpi (backup)

## Staged changes mode

```sh
git add -A
commit-message-skill              # print auto-generated message
commit-message-skill --commit     # print + commit
commit-message-skill --body       # include detailed body
commit-message-skill --area gui   # override area
```

Auto-infers area from directory structure.

## Your job

1. Read the git diff output
2. Generate a Tailscale/Go style commit message: `area: imperative verb description`
3. Area = most-changed top-level directory
4. Header ≤ 76 chars
5. **Test before commit** — reload/restart the service and verify the change works.
   Never offer to commit untested changes.
6. Present message to user. Do NOT commit without explicit user confirmation.
7. If user confirms, run: `git commit -m "area: description"` then `git push <remote> main`

## Context tools

- **Multi-command research** → `ctx_batch_execute(commands: [...], queries: [...])`
- **Read/parse files without flooding context** → `ctx_execute_file(path, code)`
- **Execute code over large output** → `ctx_execute(language, code)`
- **Search indexed knowledge** → `ctx_search(queries: [...])`
- **Index docs for recall** → `ctx_index(content/path, source)`
- **Fetch web pages** → `ctx_fetch_and_index(urls: [...])` then `ctx_search`
- **Stats/doctor/upgrade** → `ctx_stats`, `ctx_doctor`, `ctx_upgrade`
- **Prefer these over raw curl/wget** — keeps context window lean.
