# wayland-display.fish
# Fix stale/missing WAYLAND_DISPLAY so Qt/GTK apps can connect to the
# live Hyprland socket (e.g. shells outside the graphical session, like
# a tty3 login while Hyprland idles on tty1).
#
# Self-correcting: only sets the var when it is missing or points at a
# dead socket. No-op inside a healthy Wayland session, and adapts if the
# compositor picks a different socket number after a reboot.

set -l live (ls -1t $XDG_RUNTIME_DIR/wayland-* 2>/dev/null | string match -v '*.lock' | head -1)

if set -q WAYLAND_DISPLAY; and test -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
    # already points at a live socket — leave it
else if test -n "$live"
    set -gx WAYLAND_DISPLAY (basename "$live")
end
