-- #####################################################################
--  SnowDots - Hyprland Lua Config                              0.56+
--  Converted from hyprland.conf via hyprconf2lua + manual fixes
-- #####################################################################

-- ── COLOR SYSTEM ──────────────────────────────────────────────────────
-- Read colors from skwd-wall generated file
local function load_skwd_colors()
    local path = os.getenv("HOME") .. "/.cache/skwd-wall/hyprland-colors.conf"
    local f = io.open(path)
    local colors = {}
    if f then
        for line in f:lines() do
            local name, val = line:match("^%$([%w_]+)%s*=%s*([rgba%(%)%x]+)$")
            if name and val then
                colors[name] = val
            end
        end
        f:close()
    end
    return colors
end

local skwd = load_skwd_colors()
local color1   = skwd.color1   or "rgba(8839efff)"
local color4   = skwd.color4   or "rgba(cba6f7ff)"
local inactive = skwd.inactive or "rgba(000000aa)"
-- ──────────────────────────────────────────────────────────────────────

local mainMod = "SUPER"


-- ── EARLY ENV (must be first) ─────────────────────────────────────────
hl.env("XDG_DESKTOP_PORTAL_HYPRLAND_FORCE_SHM", 1)


-- #####################################################################
--  MONITOR
-- #####################################################################

hl.monitor({
    output   = "",
    mode     = "2560x1440@180",
    position = "auto",
    scale    = 1,
})


-- #####################################################################
--  ENVIRONMENT
-- #####################################################################

-- Desktop session
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Steam
hl.env("SAM_STEAM_INSTALL_ROOT", "/home/snow/.local/share/Steam")
hl.env("XKB_CONFIG_EXTRA_PATH", "/home/snow/.config/xkb")

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("NVD_BACKEND", "direct")
hl.env("__GL_GSYNC_ALLOWED", 1)
hl.env("__GL_VRR_ALLOWED", 1)
hl.env("__GL_MaxFramesAllowed", 1)
hl.env("QT_WAYLAND_FORCE_DPI", "physical")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", 1)

-- Toolkits
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Cursor
hl.env("HYPRCURSOR_THEME", "Bibata-Matugen")
hl.env("HYPRCURSOR_SIZE", 24)
hl.env("XCURSOR_THEME", "Bibata-Matugen")
hl.env("XCURSOR_SIZE", 24)


-- #####################################################################
--  AUTOSTART
-- #####################################################################

hl.on("hyprland.start", function()
    -- System / session (immediate)
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("systemctl --user restart xdg-desktop-portal-hyprland")
    hl.exec_cmd("hyprctl setcursor Bibata-Matugen 24")
    hl.exec_cmd("rm -f " .. os.getenv("XDG_RUNTIME_DIR") .. "/awww.socket")
    hl.exec_cmd("python3 ~/.local/bin/services-dashboard.py")
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("clipse -listen")

    -- Shell (quickshell directly, skip Python wrapper)
    hl.exec_cmd("qs -c caelestia -d")

    -- Wallpaper (show immediately so desktop isn't blank)
    -- Clear boot sync gate so OpenRGB always re-syncs at boot
    -- last_synced_accent persists across reboots; wall-sync.sh skips
    -- rgb-sync if the accent hasn't changed (correct at runtime, wrong at boot)
    hl.exec_cmd("rm -f ~/.cache/skwd-wall/last_synced_accent")
    hl.exec_cmd("systemctl --user start skwd")
    hl.exec_cmd("~/Dotfiles/scripts/wall-reset.sh")

    -- Lock screen (hyprlock at boot, then caelestia for manual/idle locks)
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("hyprctl dispatch workspace 1")

    -- Delayed (non-essential / slow to init)
    hl.exec_cmd("sleep 2 && awww-daemon --format xrgb")
    hl.exec_cmd("sleep 2 && ~/Dotfiles/scripts/rgb-sync.sh")
    hl.exec_cmd("sleep 3 && trayscale --hide-window")
    hl.exec_cmd("sleep 4 && discord")
    hl.exec_cmd("sleep 5 && coolercontrol")
    hl.exec_cmd("steam")
end)


-- #####################################################################
--  INPUT
-- #####################################################################

hl.config({
    input = {
        kb_layout = "us, iq(ku_ara), ara_ph",
        kb_options = "grp:alt_shift_toggle",
        numlock_by_default = false,
        follow_mouse = 1,
        mouse_refocus = false,
        accel_profile = "flat",
        force_no_accel = true,
        sensitivity = 0,
    },
})

hl.config({
    cursor = {
        enable_hyprcursor = true,
        no_hardware_cursors = true,
        min_refresh_rate = 180,
    },
})


-- #####################################################################
--  LOOK & FEEL
-- #####################################################################

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 4,
        col = {
            active_border = { colors = { color4, color1 }, angle = 45 },
            inactive_border = inactive,
        },
        resize_on_border = false,
        allow_tearing = true,
        layout = "dwindle",
    },
})

hl.monitor({
    output   = "DP-2",
    mode     = "2560x1440@180",
    position = "0x0",
    scale    = 1,
})

hl.config({
    decoration = {
        rounding = 10,
        active_opacity = 0.93,
        inactive_opacity = 0.85,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            noise = 0.01,
            contrast = 0.9,
            xray = true,
            special = true,
            popups = true,
        },
        shadow = {
            enabled = false,
        },
    },
})

-- Animations with bezier curves
hl.curve("snappy", { type = "bezier", points = { {0.2, 0.1}, {0.2, 1} } })
hl.curve("smooth", { type = "bezier", points = { {0.1, 0.8}, {0.15, 1} } })

hl.animation({ leaf = "windows",   enabled = true, speed = 3,    bezier = "snappy", style = "popin" })
hl.animation({ leaf = "windowsMove",enabled = true, speed = 2.5,  bezier = "smooth" })
hl.animation({ leaf = "fade",      enabled = true, speed = 2.5,  bezier = "snappy" })
hl.animation({ leaf = "fadeSwitch",enabled = true, speed = 2.5,  bezier = "snappy" })
hl.animation({ leaf = "fadeIn",    enabled = true, speed = 2.5,  bezier = "snappy" })
hl.animation({ leaf = "fadeOut",   enabled = true, speed = 2.5,  bezier = "snappy" })
hl.animation({ leaf = "fadeLayers",enabled = true, speed = 2.5,  bezier = "snappy" })
hl.animation({ leaf = "workspaces",enabled = true, speed = 3,    bezier = "smooth", style = "slidefade 30%" })
hl.animation({ leaf = "border",    enabled = true, speed = 1,    bezier = "default" })

hl.config({
    dwindle = {
        preserve_split = true,
        smart_split = false,
        force_split = 0,
    },
})

hl.config({
    render = {
        direct_scanout = true,
    },
})

hl.config({
    misc = {
        vrr = 2,
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        enable_swallow = true,
        swallow_regex = "^(kitty)$",
        swallow_exception_regex = "^(wev)$",
        focus_on_activate = true,
        allow_session_lock_restore = true,
        always_follow_on_dnd = true,
        layers_hog_keyboard_focus = true,
    },
})


-- #####################################################################
--  WINDOW RULES
-- #####################################################################

-- Workspace assignments
hl.window_rule({
    name  = "discord-forkgram-ws2",
    match = { class = "^(discord|io.github.forkgram.tdesktop)$" },
    workspace = "2",
})
-- hl.window_rule({ name = "steam-ws3", match = { class = "^(steam)$" }, workspace = "3 silent" })

-- Float + center (apps)
hl.window_rule({
    name  = "float-center-apps",
    match = { class = "^(clipse|skwd|dev.deedles.Trayscale|io.github.forkgram.tdesktop|swappy|mpv|coolercontrol)$" },
    float = true,
    center = true,
})

-- Float + center (games)
hl.window_rule({
    name  = "float-center-games",
    match = { class = "^(gamescope|re9.exe)$" },
    float = true,
    center = true,
})

-- Sizes
hl.window_rule({
    name  = "size-coolercontrol-swappy",
    match = { class = "^(coolercontrol|swappy)$" },
    size = "1200 800",
})

hl.window_rule({
    name  = "size-mpv",
    match = { class = "^(mpv|MPV|Mpv)$" },
    size = "1000 600",
})

hl.window_rule({
    name  = "size-clipse",
    match = { class = "^(clipse)$" },
    size = "622 652",
})

-- mpv extras
hl.window_rule({
    name  = "mpv-rounding",
    match = { class = "^(mpv|MPV|Mpv)$" },
    rounding = 10,
})

-- Kit opacity
hl.window_rule({
    name  = "kitty-opacity",
    match = { class = "^(kitty)$" },
    opacity = "0.85",
})

-- Focus / misc
-- hl.window_rule({ name = "trayscale-no-focus", match = { class = "^(dev.deedles.Trayscale)$" }, no_initial_focus = true })

hl.window_rule({
    name  = "cs2-immediate",
    match = { class = "^(cs2)$" },
    immediate = true,
})

hl.window_rule({
    name  = "cs2-stay-focused",
    match = { class = "^(cs2)$" },
    stay_focused = true,
})

-- Steam notification focus fix
hl.window_rule({
    name  = "steam-helper-opacity",
    match = { class = "steamwebhelper" },
    opacity = "1 1",
})

hl.window_rule({
    name  = "steam-notifications",
    match = { title = "^(Steam Notifications)$" },
    float = true,
})


-- #####################################################################
--  KEYBINDS
-- #####################################################################

-- ── Wallpaper ─────────────────────────────────────────────────────────
hl.bind(mainMod .. " + W",              hl.dsp.exec_cmd("skwd wall toggle"))
hl.bind(mainMod .. " + SHIFT + W",      hl.dsp.exec_cmd("~/Dotfiles/scripts/wall-reset.sh"))

-- ── System ────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + M",      hl.dsp.exit())
hl.bind(mainMod .. " + SHIFT + R",      hl.dsp.exec_cmd("~/Dotfiles/scripts/caelestia-restart.sh"))
hl.bind(mainMod .. " + SHIFT + B",      hl.dsp.exec_cmd("brave --incognito"))
hl.bind(mainMod .. " + C",              hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + C",      hl.dsp.exec_cmd("~/Dotfiles/scripts/force-kill.sh"))
hl.bind(mainMod .. " + O",              hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + A",              hl.dsp.window.alter_zorder({ mode = "top" }))
hl.bind(mainMod .. " + N",              hl.dsp.exec_cmd("quickshell -c caelestia ipc call drawers toggle sidebar"))
hl.bind("SUPER + SHIFT + Escape",       hl.dsp.exec_cmd("killall -9 re9.exe wineserver .magpie-dwm.exe"))

-- ── Power & lock ──────────────────────────────────────────────────────
-- NOTE: space between target+function — qs ipc call does NOT parse dots
hl.bind(mainMod .. " + L",              hl.dsp.exec_cmd("caelestia shell lock lock"))
hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd("~/Dotfiles/scripts/fuzzel-control.sh"))
hl.bind(mainMod .. " + SPACE",          hl.dsp.exec_cmd("~/Dotfiles/scripts/app-launcher.sh"))
hl.bind(mainMod .. " + Escape",         hl.dsp.exec_cmd("~/scripts/wlogout.sh"))
hl.bind(mainMod .. " + SHIFT + SPACE",  hl.dsp.exec_cmd("hyprctl switchxkblayout all 0"))
hl.bind("CTRL + ALT + Delete",          hl.dsp.exec_cmd("zenity --question --text='Are you sure you want to reboot?' && systemctl reboot"))

-- ── Apps ──────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + B",              hl.dsp.exec_cmd("brave --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations"))
hl.bind(mainMod .. " + D",              hl.dsp.exec_cmd("discord"))
hl.bind(mainMod .. " + F",              hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + R",              hl.dsp.exec_cmd("quickshell -c ~/.config/quickshell/rgb"))
hl.bind(mainMod .. " + Q",              hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + S",              hl.dsp.exec_cmd("~/Dotfiles/scripts/steam-launch.sh"))
hl.bind(mainMod .. " + T",              hl.dsp.exec_cmd("trayscale"))
hl.bind(mainMod .. " + V",              hl.dsp.exec_cmd("kitty --class clipse -e clipse"))
hl.bind(mainMod .. " + X",              hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mainMod .. " + Z",              hl.dsp.exec_cmd("~/Dotfiles/scripts/hypr-float.sh"))
hl.bind("CTRL + SHIFT + ESCAPE",        hl.dsp.exec_cmd("kitty btop"))

-- ── Hardware & media ──────────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume",         hl.dsp.exec_cmd("~/.local/bin/volume-log.sh +"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",         hl.dsp.exec_cmd("~/.local/bin/volume-log.sh -"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",                hl.dsp.exec_cmd("~/.local/bin/volume-log.sh mute"), { locked = true, repeating = true })
hl.bind("XF86AudioNext",                hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause",               hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",                hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",                hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Fallback manual volume binds
hl.bind(mainMod .. " + up",             hl.dsp.exec_cmd("~/.local/bin/volume-log.sh +"),  { repeating = true })
hl.bind(mainMod .. " + down",           hl.dsp.exec_cmd("~/.local/bin/volume-log.sh -"),  { repeating = true })
hl.bind(mainMod .. " + M",              hl.dsp.exec_cmd("~/.local/bin/volume-log.sh mute"))
hl.bind(mainMod .. " + SHIFT + V",      hl.dsp.exec_cmd("~/.local/bin/volume-unlimited-toggle.sh"))

-- Monitor brightness (DDC)
hl.bind("XF86MonBrightnessUp",          hl.dsp.exec_cmd("~/.local/bin/brightness-log.sh +"),  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",        hl.dsp.exec_cmd("~/.local/bin/brightness-log.sh -"),  { locked = true, repeating = true })
hl.bind(mainMod .. " + Prior",          hl.dsp.exec_cmd("~/.local/bin/brightness-log.sh +"),  { repeating = true })
hl.bind(mainMod .. " + Next",           hl.dsp.exec_cmd("~/.local/bin/brightness-log.sh -"),  { repeating = true })

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S",      hl.dsp.exec_cmd("~/Dotfiles/scripts/shot-smart.sh region"))
hl.bind(mainMod .. " + ALT + S",        hl.dsp.exec_cmd("~/Dotfiles/scripts/shot-smart.sh window"))
hl.bind(mainMod .. " + Insert",         hl.dsp.exec_cmd("~/Dotfiles/scripts/shot-smart.sh full"))

-- Text extract from screen
hl.bind(mainMod .. " + SHIFT + T",      hl.dsp.exec_cmd("~/.local/bin/textextract"))

-- Misc
hl.bind(mainMod .. " + SHIFT + F",      hl.dsp.exec_cmd("~/Dotfiles/scripts/night-light.sh"))

-- ── Focus ─────────────────────────────────────────────────────────────
hl.bind("ALT + left",                   hl.dsp.focus({ direction = "left" }))
hl.bind("ALT + right",                  hl.dsp.focus({ direction = "right" }))
hl.bind("ALT + up",                     hl.dsp.focus({ direction = "up" }))
hl.bind("ALT + down",                   hl.dsp.focus({ direction = "down" }))

-- ── Resize ────────────────────────────────────────────────────────────
hl.bind("ALT + CTRL + left",            hl.dsp.window.resize({ x = -50, y = 0 }))
hl.bind("ALT + CTRL + right",           hl.dsp.window.resize({ x = 50,  y = 0 }))
hl.bind("ALT + CTRL + up",              hl.dsp.window.resize({ x = 0,   y = -50 }))
hl.bind("ALT + CTRL + down",            hl.dsp.window.resize({ x = 0,   y = 50 }))

-- ── Move window ───────────────────────────────────────────────────────
hl.bind("ALT + SHIFT + left",           hl.dsp.window.move({ direction = "left" }))
hl.bind("ALT + SHIFT + right",          hl.dsp.window.move({ direction = "right" }))
hl.bind("ALT + SHIFT + up",             hl.dsp.window.move({ direction = "up" }))
hl.bind("ALT + SHIFT + down",           hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + H",      hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L",      hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K",      hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J",      hl.dsp.window.move({ direction = "down" }))

-- ── Swap window ───────────────────────────────────────────────────────
hl.bind(mainMod .. " + ALT + left",     hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + ALT + right",    hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + ALT + up",       hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + ALT + down",     hl.dsp.window.swap({ direction = "down" }))

-- ── Workspaces ────────────────────────────────────────────────────────
hl.bind(mainMod .. " + left",           hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + right",          hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + TAB",            hl.dsp.focus({ workspace = "previous" }))
hl.bind("ALT + TAB",                    hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + mouse_up",       hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_down",     hl.dsp.focus({ workspace = "e-1" }))

-- Workspace keys (1-10)
for i = 1, 10 do
    local key = i % 10  -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. key,      hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Move to workspace (follow) — direction keys
hl.bind(mainMod .. " + SHIFT + left",   hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + SHIFT + right",  hl.dsp.window.move({ workspace = "r+1" }))

-- Move to workspace (silent) — direction keys
hl.bind(mainMod .. " + CTRL + left",    hl.dsp.window.move({ direction = "left", workspace = "r-1", follow = false }))
hl.bind(mainMod .. " + CTRL + right",   hl.dsp.window.move({ direction = "right", workspace = "r+1", follow = false }))

hl.bind(mainMod .. " + period",         hl.dsp.exec_cmd("~/Dotfiles/scripts/nexus-open.sh"))

-- ── Mouse ─────────────────────────────────────────────────────────────
hl.bind(mainMod .. " + mouse:272",      hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",      hl.dsp.window.resize(), { mouse = true })
