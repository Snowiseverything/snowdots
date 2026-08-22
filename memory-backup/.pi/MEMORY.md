# User Memory

## About Snow

- Uses Arch-based Linux (CachyOS on Freezer, DietPi on Snowpi)
- Prefers: nano editor, fish shell, Hyprland/Wayland
- Accesses AI from phone via Telegram (@Snowcodebot)

## Preferences

- Concise responses
- Ask confirmation before making changes
- Use code blocks for terminal commands
- Always plan before coding

## Systems

- Freezer: Main workstation (192.168.0.111)
- Snowpi: RPi4 backup (Tailscale: 100.83.33.67)

## Session Notes (2026-05-12)

### Today's Setup

- Unified .hermes → .opencode for both OpenCode and Hermes
- Hermes gateway running as systemd service on Snowpi
- Telegram @Snowcodebot connected and working
- Memory system: AGENTS.md + MEMORY.md shared across both machines
- Quick save command: ~/bin/mem "thing to remember"
- After every session: ask "Should I save anything to memory?"

### Quickshell Sidebar (Notifications)

- Super+N toggles notification sidebar (was swaync)
- Super+Shift+B opens Brave incognito (was blur toggle - broken)
- Sidebar opens on hover in top-right corner (100px from top, 150px from right)
- Sidebar does NOT auto-hide when hovering notifications - acceptable tradeoff
- Current version: stable, no further changes needed

### Key Keybinds

- Super+N: Toggle quickshell notification sidebar
- Super+Shift+B: Brave incognito

### Session (2026-05-14)

- Fixed btop neon green colors - made bracket letters purple (#e4b7f3)
- Created "working" git tag on GitLab for rollback
- Added local backup sync status to snow-audit.sh
- Renamed `saudit` → `audit` alias. Created `health` alias for both-machine check
- System check: All scripts work (dotsync, wall-sync, audit)
- Found failed service: xdg-desktop-portal-hyprland (fixed with daemon-reload)
- Reinstalled Vencord for Discord
- Steam: Added windowrule to float notifications, removed workspace rule
- GPU crash: NVIDIA OOM from rauno.me in Brave - 12GB VRAM exhausted
- Fixed btop theme to use wallpaper primary color dynamically (was hardcoded #999999)
- Pushed wall-sync.sh fix to GitLab
- Zed: Fixed opencode path in settings.json (used full path)
- Wallpaper: Fixed stuck on 298.webp - removed skwd-paper, use awww directly
- Killed swaync (old notification daemon)

## 2026-05-14

- Auto-rename: systemd timer runs opencode-rename every 2 minutes (skips automation/watchdog sessions)

## Session (2026-05-16)

- Switched OC from pnpm to AUR (removed pnpm shim at ~/.local/share/pnpm/opencode)
- Deleted ~/.config/Cursor and ~/.config/cursor (~17MB Cursor editor leftover configs)
- Added fzf fish keybinds: Ctrl+R = vertical history search, Ctrl+T = files, Alt+C = cd with preview
- Alt+C: customized to show `..` for going up, plus eza preview of dir contents
- 63 yay updates pending (needs `yay -Syu` manually — no sudo in CLI)
- Keybind reload rescue: hyprland submap got stuck, fixed with `hyprctl dispatch submap reset`
- Notifications (caelestia) use Colours.palette.m3\* — already material you. scheme.json has two writers (caelestia python vs skwd-wall/matugen) that can conflict

## 2026-07-04 — Session: System audit, adult-block fix, WoL, projects

### Active Projects

- **borsay-qallat** — main project. Supabase + Expo/React Native mobile + React/Vite web. Local supabase docker stack runs on Freezer. Recent work: fixing onboarding, language persistence, scroll issues
- **csgo-skins** — PHP CS:GO skin site + dash-bot Discord economy bot
- **commit-message-skill** — OpenCode skill for commit messages
- **odysseus** — self-hosted AI workspace fork. Was running via Docker, now stopped. Not actively developed by me
- **enter-the-wired** — game modding tools (accela mods, Steam stuff)
- **pi-dashboard** — Flask dashboard running on Snowpi (RPi4)
- **n8n** — workflow automation on Snowpi at 100.83.33.67:5678
- **MAD-68-custom-animation** — web tool for MAD68 keyboard RGB
- **terminal-rain-lightning** — terminal rain effect
- **linux-discord-rich-presence** — Discord RPC for Linux
- **ClapFinder** — Android app (Kotlin)
- **attack-shark-x11-driver** — Attack Shark mouse X11 config
- **opencode** — contributor to upstream opencode repo

### Adult Block

- `toggle-adult-block.sh` (~/.local/bin/) toggles StevenBlack porn-only blocklist on/off via `/etc/hosts`. Hotkey Super+Shift+A
- Cache: `~/.cache/adult-blocklist/blocklist` (daily refresh by `cache-adult-blocklist.timer`)
- Fix: `rm ~/.cache/adult-blocklist/clean-hosts && toggle-adult-block.sh` if Permission denied (root-owned stale clean-hosts)
- System timer also exists: `update-adult-block.service` (weekly, writes directly to /etc/hosts with sudo)

### Docker Stack (running)

- **supabase:** auth, realtime, umami, rest, db, storage, meta, imgproxy (from `~/Projects/borsay-qallat/supabase/docker/docker-compose.yml`)
- **docker-studio-1:** port 8001 → 3000
- **docker-kong-1:** ports 8000, 8443
- **supabase-db:** port 5433 → 5432
- **odysseus** stopped & removed (3 containers + odysseus_default network)
- Compose project name: `docker`, network: `docker_default`

### Wake-on-LAN

- Interface enp6s0 (e8:9c:25:df:0d:e7), WoL enabled via `81-wol.rules` (sets `wol g`)
- Kernel: wakeup=enabled, power/control=auto
- Simple WOL app "offline" = ping check only. Magic packet still works if sent to broadcast (192.168.0.255)

### DNS

- systemd-resolved active (dnsmasq inactive)
- Per-link DNS on enp6s0 points to **Pi-Hole on Snowpi**: 192.168.1.35 (LAN) + 100.83.33.67 (Tailscale)
- Tailscale MagicDNS: 100.100.100.100 for tailnet hostnames (snowfinch-catfish.ts.net)
- Pi-Hole status: enabled, FTL on port 53, blocking active
- resolvectl flush-caches for clearing

## Session (2026-05-16) — OC Config Unification

- OC shared configs moved to `~/Dotfiles/.opencode/` (source of truth)
- `~/.opencode/{AGENTS.md,MEMORY.md,SOUL.md,opencode.json,skills/}` → symlinks to Dotfiles
- Created `scripts/setup-oc-sync.sh` — symlinks shared OC into `~/.opencode/` on any machine
- Added auto-heal OC symlink block to dotsync script
- Snowpi todo: pull Dotfiles, run `setup-oc-sync.sh` to populate skills/ + update MEMORY.md
- Snowpi Tailscale IP: 100.83.33.67 (note: AGENTS.md still shows old IP 100.120.197.52)

## 2026-05-17

- matugen config.toml already has all templates wired (opencode, starship, spicetify, steam, brave, gtk, vencord, clipse). starship uses symlink ~/.config/starship.toml -> ~/Dotfiles/starship/starship.toml - target file updates fine at same timestamp as other matugen outputs. Terminal apps still need restart for color changes - inherent limitation. Zombie skwd-paper process cleaned. configs all working, nothing more to wire.

## 2026-05-17

- Swaync removed from hyprland.conf exec-once. Caelestia handles notifications now (NotificationServer in Notifs.qml). spicetify backup apply fails with permission denied on /opt/spotify/Apps - needs 'sudo chmod a+wr /opt/spotify/Apps -R && spicetify backup apply' run manually.

## 2026-05-18

- Caelestia live config is at ~/.config/quickshell/caelestia/ - separate copy from ~/Dotfiles/quickshell/caelestia/. Edits to QML files must be copied to ~/.config/quickshell/caelestia/ to take effect. Lock screen Center.qml changed: .face icon replaced with current wallpaper (Wallpapers.current) in rounded rectangle. Dashboard profile pic already uses Wallpapers.current. 7 other QML files also differ between dotfiles and live.

## 2026-05-18

- wall-sync.sh now writes wallpaper path to ~/.local/state/caelestia/wallpaper/path.txt (caelestia's wallpaper tracker). Lock screen uses Wallpapers.current which reads from this file. Live caelestia config at ~/.config/quickshell/caelestia/ - edits to Dotfiles/quickshell/caelestia/ must be copied over (not symlinked).

## 2026-05-18 (Lock Screen Alive)

- LockSurface.qml: double-click blurred wallpaper opens `skwd wall toggle` via Process
- NotifGroup.qml: swipe-to-dismiss notifications (horizontal drag past 100px threshold, calls n.close() for app group)
- Media.qml: album art breathing pulse (1.0↔1.03) when playing + 24-bar sine-wave visualizer
- Center.qml: clock text breathing (1.0↔1.02, 4s InOutSine loop)
- Content.qml: all side panels (weather, fetch, media, resources, notifs) scale up 1.02 on mouse hover (HoverHandler + transform)
- WeatherParticles.qml (new): live particles based on Weather.icon — rain lines, snow circles, fog/cloud blobs, clear sky sparkles
- All QML edits done in both Dotfiles/quickshell/caelestia/ and ~/.config/quickshell/caelestia/

## 2026-05-20

- Session 2026-05-20: Millennium, Metropolis, opencode-desktop-bin, Shelly, Snowflake GIF, Textextract

- Millennium installed via steambrew.app (beta v3.0.0-beta.24). Needs sudo for /usr/lib/millennium/ + symlinks to ~/.steam/steam/ubuntu12\_{32,64}/
- Metropolis AUR upgrade 0.1.2->0.1.3 failed: PKGBUILD has cargo build --release --locked, Cargo.lock needs update. Fixed by removing --locked. Re-edit on every yay upgrade.
- opencode-desktop-bin installed (source build failed: node-gyp ETIMEDOUT for Node 26.1.0 headers). Had file conflicts from prior install at /opt/OpenCode/, /usr/bin/, /usr/share/applications/, icons, licenses. Fixed by removing all then pacman -U.
- Shelly orphaned pacman db entry at /var/lib/pacman/local/shelly-2.3.0.2-1/ removed (missing desc/files, binary gone, required by none)
- Created ~/.config/quickshell/caelestia/assets/snowflake.gif (128x128, 12 frames, falling snowflakes with glow) for power menu. Added paths.sessionGif to ~/.config/caelestia/shell.json
- Textextract (~/.local/bin/textextract): grim+slurp -> tesseract OCR -> wl-copy. Added notification feedback. Bind at ~/.config/hypr/hyprland.conf:287 ($mainMod SHIFT, T)
- Discord matugen theme confirmed working: vencord template imports Midnight framework, overrides with matugen wallpaper colors

## 2026-05-21

- skwd daemon crashed: trailing comma in ~/.config/skwd-wall/config.json (edit removed postProcessing entry but left trailing comma). Picker worked after fix + daemon restart. skwd colors.json now in ~/.cache/skwd-wall/ with both accent/background/foreground + M3 palette keys (generated by skwd-colors.json matugen template). rgb-sync.sh forces hue to 210° blue for consistent blue RGB theme

## 2026-05-21

- rgb-sync.sh: per-device OpenRGB calibration. Reads matugen accent from ~/.cache/skwd-wall/colors.json. Fans (device 2): accent hue, L=0.35 S=0.80. RAM (device 0,1): -20° hue shift, L=0.30 S=0.90 (compensates ENE yellow tint). --brightness 50 on all. Single openrgb call per device for speed (was 4.1s, now 1.4s). accent hue changes per wallpaper

## 2026-05-21

- RGB race condition fixed: skwd ExternalMatugenCommand had -c %config% which pointed to skwd config (no skwd-colors.json template). Fixed: removed -c flag so matugen uses default config.toml (has all 16 templates). rgb-sync moved from skwd postProcessing to matugen post_processing (runs AFTER colors.json generated). skwd postProcessing was racing with matugen - rgb-sync read stale colors.json before matugen finished.

## 2026-05-22

- MAD68 HE keyboard RGB protocol: uses 32-byte HID output report via hub.f.gg format [7, 65, 2, 0, 0x96, R, G, B, 0xB1, zero-pad]. Previously tried Pro protocol (55 0B 64-byte chunks) which didn't work for HE (PID 0x1058). WebHID JavaScript worked, Python hidapi works. Udev rule at /etc/udev/rules.d/99-mad68.rules needed for hidraw write access. Keyboard must be in customization mode.

## 2026-05-22

- skwd config tracked in Dotfiles (symlinked). rename-wallpapers.sh type changed from static to all (runs after Wallhaven downloads)

## 2026-05-24

- fastfetch: removed docker command from config.jsonc + wall-sync.sh template (was hanging 5s)
- 10 OC subagents created: health-monitor, pkg-manager, snowpi-bridge, tailscale-manager, docker-orchestrator, docker-cleanup, backup-agent, disk-usage, dotfiles-sync, log-scanner
- oc-sync.sh: Tailscale IP, ~/.agents/ sync, bidirectional SQLite merge (INSERT OR IGNORE)
- 30min auto-sync timer (oc-fast-sync.timer) enabled
- Granular bash permissions: safe cmds auto-allow, dangerous ask
- Root disk space: deleted old btrfs snapshots (6), 100% to 55% (17G free)
- System updated: sudo pacman -Syu
- ACCELA accent wired to wall-sync.sh: reads primary from colors.json, updates ACCELA.conf
- Cache merged back: /home/.cache-root to /var/cache/, stray symlink removed
- Wallpaper source file: /home/snow/Pictures/Wallpapers/328.webp

## 2026-05-30

- 2026-05-30: OC remote control setup. Installed @lesquel/opencode-pilot globally. Dashboard on :4097 (token: snowefb35112). Systemd opencode-serve.service on :4096 with pilot on :4097. Created ~/scripts/oc-sync.sh for Freezer->Snowpi sync (configs + dotfiles + sessions). Boot sync + 5-min timer for memory/dotfiles. Autostart optimized: qs -c caelestia -n -d (skips Python wrapper, no sleep), skwd + wall-reset.sh immediate, heavy apps delayed. QML cache sparse (only 1 file) - caelestia cold boot slower. /dev/sda3 LUKS 16.4s boot bottleneck. Autostart no longer uses waypaper

## 2026-05-30

- Starship: separate per-machine Dotfiles repos. Freezer = Arch prompt, Snowpi = raspbi prompt. Both pushed to GitLab. Snowpi gitlab: sn0wman/snowpi-dotfiles

## 2026-05-30 (late)

- Fixed: missing `zoxide init fish | source` in config.fish (cd alias to z was broken)
- Fixed: `ff` abbr for `find . -type f -name` conflicted with `alias ff=fastfetch`. Renamed to `ffind` on both Freezer and Snowpi
- MTP phone not showing in file manager: missing `gvfs-mtp` package. Install: `sudo pacman -S gvfs-mtp`
- setup-freezer.sh had stray `fi` at line 63 (no matching if). Removed.
- Created matugen SDDM template for silent theme (`Dotfiles/matugen/templates/sddm-silent.conf`). No wallpaper — uses solid matugen surface color as background like catppuccin presets.
- SDDM is SilentSDDM theme v1.4.2 at `/usr/share/sddm/themes/silent/`. Configs/ has catppuccin presets built in.
- Phone images backed up at `/mnt/backups/NothingPhone/` (41G).
- Setup script at `~/scripts/setup-sddm.sh` copies matugen config to theme dir (needs sudo).

## 2026-07-23 — System maintenance, session DB fix, Snowpi cleanup

### Session DB Fix

- All 83 sessions moved to `global` project — visible from any directory
- `proj_home_snow` + `proj_viymess` removed (conflicted with global)
- Created `~/scripts/opencode-switch` — list sessions by number, pick & resume
- Also in `~/Dotfiles/scripts/opencode-switch`

### Freezer System State

- **~130 packages pending** (needs `sudo pacman -Syu`):
  - Hyprland 0.55.4 → 0.56.0
  - Kernel 7.1.3 → 7.1.4
  - Opencode 1.18.3 → 1.18.4
  - QEMU full stack bump, lame 3→4
- **15 orphaned packages** — can remove with `sudo pacman -Rns $(pacman -Qdtq)`
- **Pacman cache:** 3.5G — `sudo paccache -rk2` keeps last 2 versions
- **Btrfs:** fstrim.timer active (weekly). /mnt/data at 98% — needs attention (snapshot cleanup or expansion)

### Snowpi Status (100.83.33.67)

- **Uptime:** 9.5h, load 0.29
- **Disk:** 86% (7.7G free of 57G)
- **Memory:** 2.2G used / 5.5G available
- **No pending updates** — fully up to date
- **Failed service:** mnt-freezer.mount (NFS — Freezer was off, safe to ignore)
- **Projects/:** 17G — needs cleaning (pull needed data to Freezer, remove from Snowpi)
- **3 old kernels:** linux-image-6.12.75, 6.18.29, 6.18.33 (can purge)
- **Docker:** 100M docker-ce, 86M containerd.io, 66M docker-buildx-plugin

### Todo (needs sudo — run manually)

```
# Freezer
sudo pacman -Syu
sudo pacman -Rns $(pacman -Qdtq)  # remove orphans
sudo paccache -rk2                 # clean pkg cache to last 2 versions
sudo btrfs scrub start /           # annual btrfs scrub
sudo btrfs scrub start /home
sudo btrfs balance start -dusage=50 /mnt/data  # if space low

# Snowpi
ssh snow@100.83.33.67
sudo apt-get purge linux-image-6.12.75+rpt-rpi-v8 linux-image-6.18.29+rpt-rpi-v8 linux-image-6.18.33+rpt-rpi-v8
sudo apt-get autoremove --purge -y && sudo apt-get autoclean
sudo docker system prune -af --volumes
sudo journalctl --vacuum-size=100M
# then remove Projects/ after confirming data safe on Freezer
```

## 2026-07-23 (continued) — OC config fix, fade-rgb Direct mode patch

### Opencode

- Fixed extra parenthesis in `~/.config/opencode/opencode.json` (was in MCP server config)
- Removed local dev build at `~/Documents/opencode/` — symlink was at `~/.local/bin/opencode` overriding system package
- Now using system package: `/usr/bin/opencode` v1.18.3 (from CachyOS repo)
- v1.18.4 available in repo (pending `sudo pacman -Syu`)

### fade-rgb.py fix

- RAM devices faded smoothly but case fans/AIO/ARGB strip jumped instantly
- Root cause: OpenRGB plugin differences — RAM supports smooth `set_colors` + `show` in any mode, other controllers jump in `Static` mode
- Fix: switch all OpenRGB devices to `Direct` mode before crossfade loop, restore original mode + set final color after
- `Direct` mode gives software full per-LED control, every frame applies equally to all devices
- File: `~/Dotfiles/scripts/fade-rgb.py`

### RGB Sync Architecture

- `rgb-bridge.service` on port 5070 — REST API for OpenRGB + MAD68 + Govee
- `wall-reset.sh` (Super+Shift+W) → hits `localhost:5070/sync` → bridge runs `fade-rgb.py` + `govee-led.py` in parallel
- `fade-rgb.py` crossfades OpenRGB + MAD68 keyboard (20 frames, 30ms)
- `govee-led.py` sends to Govee BLE daemon socket or direct BLE / HA fallback

```

## 2026-08-01
- Thunar hides /etc/fstab-mounted drives — udisks2 sets HintSystem=true. Fix: udev rule ENV{UDISKS_SYSTEM}='0' by FS UUID in /etc/udev/rules.d/90-external-drives.rules, reload + trigger + restart udisks2. Fish has no heredocs: echo '...' | sudo tee.

## 2026-08-01
- Created memory-management pi-skill (~/.pi/agent/skills/memory-management/SKILL.md) + OpenCode subagent (~/.opencode/agents/memory-manager.md). Both pushed to GitLab SnowCode repo. Agent uses direct file edits (no mem script), scoped permissions.

## 2026-08-01
- Created pi-native memory-manager subagent at ~/.agents/code-analysis.memory-manager.md — same functionality as OpenCode agent. Delegable via subagent tool: agent='memory-manager'. Both pi subagent + OpenCode agent now exist, reading same MEMORY.md/AGENTS.md.

## 2026-08-01
- Added commit discipline constraint to AGENTS.md, MEMORY.md, memory-manager agent (OC + pi subagent), and skill. Rule: never commit without Snow approval, use snow-commit format.
```

## 2026-08-01 — Standing Preferences

- **Web search auto-approved:** anysearch is the approved web provider; run `web_search`/`anysearch` without asking. Batch 2–4 varied angles for research; full content inline.
- ScriptCat is split across two extension IDs: official `ndcooe` (Chrome Web Store — holds the LIVE userscripts, the leveldb scriptcat-mgr/scriptcat-mcp target) and beta `odnlmah` (unpacked at /home/snow/Downloads/scriptcat-v1.5.0-beta-chrome — exposes the `/agent/mcp` Add-Server panel; its MCP config is written to chrome.storage.local/sync only after UI use, so there's no mcp key to pre-seed).
- `scriptcat-mcp` (~/scripts/scriptcat-mcp) = stdio MCP server (JSON-RPC 2024-11-05) mirroring scriptcat-mgr's leveldb contract; tools: list_scripts, get_script, install_script(file|url), remove_script, update_scripts, kv_list/kv_set/status. Default kills Brave for write access; `NO_KILL=1` skips.
- pi gateway caches mcp.json at session start (HTTP `url` servers only) — stdio servers aren't hot-loaded mid-session, but the stdio MCP is fully tested directly and callable by any stdio-capable MCP host.
- 2026-08-01: scriptcat-mcp SSE bridge active on :9191 (NO_KILL child; never kills Brave). Live scripts in ndcooe: Reddit++ 2.1.6, Reddit NSFW Unblur, Bypass All Shortlinks 96.8, Pagetual 1.9.37.132, Picviewer CE+ 2026.2.6.1 (5 total, all updates=yes). SponsorBlock absent from GreasyFork (pulled). mcp.json: scriptcat={url:<http://127.0.0.1:9191/sse}>. Panel auto-registration blocked (Brace shields on chrome-extension:// options). Install workflow: stop Brave -> MCP install -> relaunch.
  /home/snow/.opencode/MEMORY.md
- 2026-08-01: ROUTING FIX — scriptcat-mcp-sse now accepts POST on /message,/sse,/,/sse//mcp; GET /sse emits ABSOLUTE endpoint. Fixes ScriptCat panel 'MCP request failed: 404'. Service restarted (active). Installed via fixed POST /sse: Bypass All Shortlinks 96.8, Pagetual 1.9.37.132, Picviewer CE+ 2026.2.6.1, Greasyfork Search w/Sleazyfork 1.6.6. ndcooe total=6; all updates=yes. SponsorBlock: no live GF source (not fabricated).
  /home/snow/.opencode/MEMORY.md
- viymess email: RECOMMEND sending via subdomain (e.g. updates.viymess.com) in Resend rather than root viymess.com, to avoid merging SPF with Spacemail mailbox SPF (root currently v=spf1 include:spf.efwd.spaceship.net ~all, no resend include). DKIM CNAME resend._domainkey empty. DMARC p=none set. RESEND_API_KEY not yet on vercel. Route /api/waitlist fail-soft: sends branded email from hello@<updates@updates.viymess.com> via Resend once key + domain live; Telegram owner alert always fires.
- viymess Resend: the api-keys-<ts>.csv "token" column is MASKED/truncated (14-char re_iDk... -> Resend 400 "API key is invalid"). Use the FULL key value copied once at creation (~39 chars, re_...) OR paste directly. Validate candidate via GET <https://api.resend.com/domains> (200=valid, 400=invalid) before wiring to VERCEL env RESEND_API_KEY; from=Viymess <hello@viymess.com> (root domain is now SPF-merged with spaceship, DKIN+DMARC p=none present). Route fail-soft until key present.

## 2026-08-05 — Tailscale DNS + 1.1.1.1 fallback

- Freezer: Tailscale v1.98.10, `100.87.27.79` (active + enabled at boot).
- `tailscale set --accept-dns=true --accept-routes=true` — no sudo needed (socket is root-accessible), applies live + persists.
- Tailnet MagicDNS suffix: `snowfinch-catfish.ts.net` (.ts.net names resolve: snowpi -> 100.83.33.67, freezer -> 100.87.27.79) via the Tailscale 100.100.100.100 stub -> Pi-hole on Snowpi (100.83.33.67) -> Cloudflare upstream.
- DNS chain: tailscale0 (100.100.100.100, +DefaultRoute) -> tailnet resolver 100.83.33.67 -> upstream; .ts.net split-DNS -> 199.247.155.53.
- `FallbackDNS=1.1.1.1` added to `/etc/systemd/resolved.conf` (needs sudo). Global DNS stays 192.168.0.1 1.1.1.1. When Pi-hole/Snowpi unreachable, systemd-resolved falls back to 1.1.1.1 directly.
- Idempotent re-apply: `sudo bash ~/scripts/configure-tailscale-dns.sh` (sets FallbackDNS + restarts systemd-resolved, verifies).
- `--accept-routes` pulled in 192.168.0.0/24 from the tailnet (LAN routable over Tailscale).
- Verified live: snowpi.snowfinch-catfish.ts.net -> 100.83.33.67; google.com resolves via Pi-hole upstream; LAN devices reachable.

## 2026-08-05 — anysearch CLI replaces fish function

- Replaced the fish `anysearch` function with a compiled Go CLI binary at `/home/snow/.local/bin/anysearch`.
- The Go CLI wraps AnySearch's MCP HTTP endpoint (`https://api.anysearch.com/mcp`) directly — same backend as the Pi `web_search` tool, 1000 free req/day, no API key.
- Features: search, extract (full page content via `--extract`), batch parallel queries (`--batch`), provider listing (`--providers`), help (`--help`).
- Build: `go build` from source at `~/.local/src/anysearch-cli/` (source deleted after install, binary is self-contained ~9MB).
- The fish function was removed from `~/.config/fish/functions/anysearch.fish`.
- 2026-08-05: scriptcat-mgr hardened (install/update/restore now AUTO-BACKUP first to ~/scripts/userscripts/backups/<ts>/; write_script is add-only with collision guard — never clobbers existing entries; duplicate installs warn + add beside, don't replace). Verified: 9 scripts preserved across installs. Live set (9): Pagetual 1.9.37.132, Bypass All Shortlinks Debloated, Greasyfork Search w/Sleazyfork 1.6.6, OmniChess 1.0.0, Picviewer CE+ 2026.2.6.1, Reddit NSFW Unblur, Reddit++, Matugen Material You Theme, Ultimate Popup Blocker 2 (new). Restored via backups at ~/scripts/userscripts/ (Reddit++, Reddit NSFW Unblur, matugen-theme.user.js) after earlier installs wiped them.
- 2026-08-05: Bypass shortlinks fixed — debloated fork (codeberg gongchandang49) has NO adf.ly support (dropped); original greasyfork #431691 v96.8 HAS adf.ly (34 refs) but no ouo.io. Both installed (complementary): "Bypass All Shortlinks" 96.8 + "Bypass All Shortlinks Debloated". Test: real adf.ly link should auto-redirect; ouo.io shows #btn-main click-after-4s.
- 2026-08-05: Pi-Hole popunder fix APPLIED — hagezi Pro (218k ABP) + hagezi PopUp Ads (54k) lists enabled, pro.plus disabled (aggressive tier), exact denies: hai8g.com/1xlite.com/who.io. Gravity 578k→851k. Backups: /home/snow/gravity.db.bak-20260805-232843, pihole.toml.bak-*. v6 API: POST /api/lists?type=block (type in QUERY STRING), POST /api/domains/deny/exact, auth via sid header + cli_pw password.
- 2026-08-05: Query-log sweep — blocked whiopfwto.in via regex wildcard `(\.|^)whiopfwto\.in$` (Singapore AS7979 bulletproof popunder net). cawsg.com already caught by hagezi PopUp Ads. v6 regex deny: POST /api/domains/deny/regex with SINGLE backslashes (raw string in py = literal). Reload: pihole reloaddns needs root but regex applies live via FTL.
- 2026-08-05: Pi-hole DNSSEC ON + maxDBdays 7→91 via /home/snow/enable-dnssec.sh on snowpi (v6 has NO setdnssec/setdblog CLI — edit pihole.toml + restart pihole-FTL; [dns] dnssec at line 175, [debug] dnssec at 1653 leave alone; regex sub in py needs \g<1> not \191). Verified: dnssec-failed.org SERVFAIL, blocking intact.

## 2026-08-06 — ScriptCat userscripts: full root-cause + fix (14 scripts live)

### Root causes found (3 independent bugs)

1. **scriptcat-mgr parser regex `@(\w+)` misses hyphenated keys** — `@run-at` never captured → default `document-idle` written into compiled resource → Chrome userScripts.register() rejects ("Invalid value for runAt"). FIXED: `@([\w-]+)` + `to_chrome_run_at()` mapping (`document-start`→`document_start`, `document-end`→`document_end`, else `document_idle`).
2. **`http*://` match scheme** (TM-ism, Greasyfork Search) — Chrome scheme whitelist only allows http/https/*/file; `http*` → "Invalid scheme". FIXED: `normalize_scheme()` converts `http*://`/`https*://` → `*://` (applied to BOTH match_urls AND metadata['match'] since ScriptCat rebuilds compiled resources from metadata).
3. **Local backup corruption** — Reddit++ stored code had binary garbage (NUL bytes at line 108, `_node_modules_css_loader...`) from a restored backup → SyntaxError killed whole script silently (no window key, no console error, parse-time failure). FIXED: reinstall from original source (greasyfork #490046 v2.1.6). **Rule: ALWAYS fetch scripts from original source, never restore from local backup** (user directive).

### Key ScriptCat mechanics

- Compiled resource `runAt` must be Chrome enum form. `scriptUrlPatterns` must be POPULATED (empty → ScriptCat re-parses raw scriptCode, reintroducing http*:// + TM runAt → registration fails).
- Registration guard: SW skips re-registration if `registerState===REGISTER_DONE` && scriptcat-inject exists → after storage changes MUST `chrome.userScripts.unregister()` + `chrome.runtime.reload()` to force clean re-registration.
- Popup "enabled and running in background" group is ONLY for type-2 background scripts (`dealBackgroundScriptInstall` filters `r.type!==1`); page userscripts (type 1) always appear only in "current page running scripts". Empty background group = NORMAL.
- Registered script code = compiled wrapper `window['#<uuid>'] = function(){...})(); ... }).call(this);}` — if the inner code has a SyntaxError, the whole script dies at parse time (no error surfaces).

### Current state (verified live on reddit)

- **14 scripts + 2 dispatchers (scriptcat-inject/scriptcat-content) registered**, all type:1 status:1, no binary corruption: Pagetual, Bypass Debloated, Reddit Age Bypass, OmniChess, Picviewer CE+, Reddit++ (NEW uuid 5fa6ae9f after reinstall), Reddit NSFW Unblur, Bypass All Shortlinks, Privacy Redirector, Matugen, Universal Link Cleaner, Greasyfork Search (matches now `*://greasyfork.org/*` etc), Ultimate Popup Blocker, Reject cookie banners.
- NSFW Unblur + Reddit++ verified executing on <www.reddit.com> (window keys `#-6988063c-8c...` and `#5fa6ae9f-b35...`).
- ScriptCat pin still in Brave toolbar (pinned_extensions list includes jaehimm...).
- scriptcat-mgr fixed tool at `~/scripts/scriptcat-mgr`; new scripts in `~/scripts/userscripts/` (reddit-age-bypass, reject-cookie-banners, universal-link-cleaner, privacy-redirector, reddit-plus-plus, greasyfork-search .user.js).
- uBO NOT installed — "essential filters" half of the age-bypass plan still needs manual CWS install (user action).
- 2026-08-06: ScriptCat's built-in AI Agent (Model Service) is a PLAIN CHAT CLIENT — no tools, NO access to installed scripts/storage. It only does `${baseUrl}/chat/completions` (OpenAI format) + `${baseUrl}/models`. Cannot list/read/create/manage userscripts despite what it claims. For script management ALWAYS use scriptcat-mgr + CDP/scriptcat-mcp instead.
- 2026-08-06: ScriptCat AI Agent provider config (works): Provider=openai (default), API Base URL=`https://opencode.ai/zen/go/v1` (opencode-go gateway, key from `~/.local/share/opencode/auth.json`), Default Model=`qwen3.7-plus`/`minimax-m3`/`kimi-k2.7-code`. GOTCHA: trailing space/slash in base URL → `${base}/models` 404s → ScriptCat's Fetch Models has NO error catch (silent fail, dropdown stays stale). Also: opencode local serve (4096) is native REST (sessions/PTY), NOT OpenAI-compatible — can't be used as ScriptCat base URL.
- 2026-08-06: VRR on Microstep G274QPF E2 (Freezer): works. Requires (1) monitor OSD Adaptive Sync ON — driver reports `vrr_capable:0` until enabled (this was the silent killer), (2) Hyprland 0.56 Lua config `misc.vrr = 2` (2=fullscreen-only, 1=always, 0=off) in ~/Dotfiles/hypr/hyprland.lua. Runtime: `hyprctl eval 'hl.monitor({ output = "DP-3", mode = "2560x1440@180", position = "0x0", scale = 1, vrr = 2 })'` — NOT hyprctl keyword (0.55+ needs Lua). Verify: `hyprctl monitors -j` → vrr true only in fullscreen. Game setting: RE9 FrameRate=Variable + VSync=False (uncapped, VRR handles 70-110fps; Max120 was the no-VRR fallback).
- 2026-08-06: viymess deploy = GitLab integration only. Project linked to gitlab sn0wman/viymess (productionBranch main, rootDirectory apps/storefront). NO `.gitlab-ci.yml`, NO snowpi build — the double-build was Vercel git integration (source:git on push) PLUS manual `vercel deploy --yes` (source:cli) in the same command chain. DECISION: Option A — stop CLI deploys, push to origin only; Vercel auto-builds per branch. Git-push failures (lockfile/standalone ENOENT) fixed in 462fb82+b17eaef so git builds pass. Single-push config: push.default=simple, remote.pushDefault=origin, main tracks origin/main. Snowpi stays fetch-only mirror. Landing+analytics work on dev-sprint1; main untouched (old Georgia build).

## 2026-08-14

### viymess Railway deployment status

- Pushed commit `5b8cee2` to GitLab `dev-sprint1` with deployment fixes: `.dockerignore` excludes backend `.env`; `apps/medusa-backend/docker-entrypoint.sh` copies `.medusa/client` → `.medusa/admin` and writes a minimal runtime `.env` from container env.
- Railway redeploy `ef0ea154-441d-4073-87d0-a0961e1d4c6c` succeeded, but live backend `https://medusa-backend-production-012c.up.railway.app` still returns `502`.
- Root cause: Railway appears to be using a stale cached snapshot rather than the newly pushed GitLab source; runtime logs show no new entrypoint behavior and still crash with `Could not find index.html in the admin build directory`.
- Local Docker testing proved the fixes work in principle: `.dockerignore` excludes `.env`, admin build copy works, runtime `.env` generation works, and the container can start when given proper env.
- Railway env already has required secrets: `DATABASE_URL` (Neon pooler), `COOKIE_SECRET`, `JWT_SECRET`.
- Next actions: reconnect GitLab source in Railway web UI, or use `railway up` for a local-direct deploy; do not assume `--from-source` refreshes from GitLab.

### Docker disk pressure

- Docker build cache on `/home/docker-data` is ~24.54 GB; `/home` is at 88% used. `docker run` failed with `no space left on device` despite root `/` showing 36 GB free.
- Fix: `docker system prune -f` to reclaim ~19.8 GB from unused build cache.

## Bafra Swarm — Workspace Rules

- **Repos:** `swarm-core`, `swarm-mobile`, `swarm-dashboard`
- **Workstations:** Joseph (CachyOS desktop), Mahamad (CachyOS Dell laptop)
- **Branching:** All development starts on and targets `dev`; never commit directly to `main` or production branches.
- **Editor:** `nano` only; never `micro`.
- **Tracking:** Update `Progress.md` when task state changes.
- **Mandatory Testing Rule:** Never commit or push code without testing it first—either run by the local agent, Joseph, or Mahamad. Code must be verified functional before merging into `dev` or `main`.

## 2026-08-22 — Snowpi architecture doc + DNSSEC fix

### Committed (local bare repo only — not public)

- Created `~/Dotfiles/docs/Snowpi/architecture.md` — Snowpi services, compose projects, Caddy vhosts, DNS chain, ports, Tailscale mesh, gotchas, plus full DNSSEC writeup.
- Committed `58274c8` ("docs: add Snowpi architecture and DNSSEC reference"), pushed ONLY to `snowpi` local bare repo (`snow@100.83.33.67:/home/snow/git-vault/Dotfiles.git`). GitHub/GitLab untouched.
- Doc is in `~/Dotfiles/docs/` Obsidian vault, mirrors `Freezer PC/architecture.md`.

### DNSSEC fix (Snowpi) — root cause + resolution

- **Symptom:** slow/failing lookups via Pi-Hole.
- **Root cause:** double DNSSEC validation. FTL (dnsmasq) `dnssec` flag AND Unbound already validating = duplicate crypto, extra chain-of-trust lookups, bigger responses (TCP fallback), SERVFAIL storms (RPi has no RTC — clock skew before NTP sync makes sigs verify as expired).
- **Fix:** validate ONCE at Unbound only. `/etc/pihole/pihole.toml` → `dnssec = false` (was `true ### CHANGED`); `/etc/pihole/dnsmasq.conf` → `dnssec` line commented. Restart `pihole-FTL`. Verified `dig @192.168.1.35 google.com` → NOERROR ~15ms.
- **Rule going forward:** FTL DNSSEC stays OFF; Unbound does validation. Toggle via `sudo pihole -a dnssec`.

### Snowpi SSH gotcha

- Snowpi default shell is **fish**. Inline bash `for` loops and `$var` in `ssh "..."` strings fail. Use a script: `scp` it over then `ssh ... 'bash /tmp/script.sh'`.
