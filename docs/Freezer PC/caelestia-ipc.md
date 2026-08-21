# Caelestia IPC Notes

## Quirk: Dots are NOT separators in `caelestia shell`

`qs ipc call` expects target and function as **separate CLI arguments**.

```
caelestia shell lock lock      # ✓ works — calls lock() on target "lock"
caelestia shell lock.lock      # ✗ fails — "lock.lock" treated as single target string
```

`qs` parses `lock.lock` as one arg → assigns it as target name → finds no function → **"Function required to send message."**

### Why this happens

`caelestia shell` passes its message args directly to `qs -c caelestia ipc call <args>`. Argparse collects all positional args into a list. When you write `lock.lock`, it's one string. When you write `lock lock`, it's two strings — one for target, one for function.

### Pattern

```
caelestia shell <target> <function> [args...]
```

### All IPC targets (from `caelestia shell -s`)

| target     | functions                                                          |
| ---------- | ------------------------------------------------------------------ |
| lock       | lock(), unlock(), isLocked()                                       |
| audio      | cycleOutput()                                                      |
| brightness | get(), getFor(), set(), setFor()                                   |
| drawers    | toggle(), list()                                                   |
| hypr       | refreshDevices(), cycleSpecialWorkspace(), listSpecialWorkspaces() |
| mpris      | list(), play(), pause(), playPause(), previous(), next(), stop()   |
| nexus      | open()                                                             |
| notifs     | disableDnd(), toggleDnd(), isDndEnabled(), clear(), enableDnd()    |
| picker     | open(), openFreeze(), openClip(), openFreezeClip()                 |
| toaster    | info(), success(), error(), warn()                                 |
| wallpaper  | set(), get(), list()                                               |

### Keybind + hypridle

```
bind = $mainMod, L, exec, caelestia shell lock lock

# hypridle.conf
lock_cmd = caelestia shell lock lock
before_sleep_cmd =
after_sleep_cmd = hyprctl dispatch dpms on && sleep 0.5 && caelestia shell lock lock
```
