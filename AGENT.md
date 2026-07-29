# Dotfiles — Agent Instructions

## Workflow

- **Test before commit:** After editing QML, Lua, shell scripts, or any Dotfile, always reload the service (hyprctl reload, restart caelestia, etc.) and verify the change works before committing and pushing.
- **Caelestia restart:** `killall -9 quickshell; sleep 2; qs -c caelestia -d &` — wait for "Configuration Loaded" in logs before testing.
- **Hyprland config reload:** `hyprctl reload config` then verify with `hyprctl getoption` or `hyprctl animations`.
- **Three remotes:** GitHub (public, sanitized), GitLab (private, full), Snowpi (bare repo). Push to all three every time.

## Projects

- **Caelestia QML** (`quickshell/caelestia/`) — Shell UI, uses CustomMouseArea that aggregates/consumes wheel events. Top-level Interactions.qml covers the full screen and accepts all mouse events — child MouseAreas must use `event.accepted = true` to prevent event capture.
- **Hyprland Lua** — Animation leaves have sub-leaves in 0.56+ (fadeSwitch, windowsMove, etc.). Set them explicitly; the parent leaf doesn't cascade.
- **Scripts** — Bash scripts at `scripts/`, shellcheck-clean.
