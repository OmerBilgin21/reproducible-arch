#!/usr/bin/env bash
#
# Ports the keybinds/niceties from config-linux/hypr/ (Hyprland) onto the new
# Plasma 6 + Krohnkite 0.9.9.2 setup. Idempotent: safe to re-run.
#
# What this does NOT touch (Plasma/KWin already handles it natively):
#   - media keys (volume/brightness/playback) - already bound via kmix/org_kde_powerdevil
#   - touchpad natural-scroll / clickfinger / scroll speed - per-device group names in
#     kcminputrc are dynamically generated and unpredictable before first use; set these
#     once in System Settings > Input Devices > Touchpad instead
#   - lock screen (already Meta+L), screenshots (already bound to Spectacle via
#     PrintScreen family), notifications center
#
# What it deliberately overrides vs. Krohnkite/KWin's shipped defaults, and why,
# is in the PR/commit message / chat summary, not repeated here.
#
# CAVEAT (Plasma 6.8.2): kglobalaccel caches a custom-command component's *first-ever*
# registered shortcut and silently reverts later kglobalshortcutsrc edits back to it on
# the next login - a known bug. This script is fine on a genuinely fresh install (nothing
# cached yet), but if you ever need to CHANGE one of the make_launcher shortcuts below on a
# system where it's already registered, editing the value here and re-running is not enough;
# you also need to delete ~/.local/share/applications/hypr-port-<id>.desktop, kbuildsycoca6,
# recreate it, and only then write the new _launch value - i.e. re-run this whole script only
# after `rm ~/.local/share/applications/hypr-port-*.desktop && kbuildsycoca6`.
#
# This is NOT wired into any autostart/login hook - it only ever runs when invoked by hand.

set -euo pipefail

KWC() { kwriteconfig6 --file kglobalshortcutsrc --group "$1" --key "$2" "$3"; }
KWINC() { kwriteconfig6 --file kwinrc --group "$1" --key "$2" "$3"; }
INC() { kwriteconfig6 --file kcminputrc --group "$1" --key "$2" "$3"; }
XKB() { kwriteconfig6 --file kxkbrc --group "$1" --key "$2" "$3"; }

echo "==> Krohnkite shortcuts: resolving collisions with Hyprland muscle memory"
# Toggle Float: Hyprland uses SUPER+V, Krohnkite ships Meta+F (which we want free for fullscreen)
KWC kwin KrohnkiteToggleFloat "Meta+V,none,Krohnkite: Toggle Float"
# Decrease: Hyprland has no equivalent key; Meta+D collides with native "Show Desktop".
# Pair it with Increase (Meta+I) instead: Meta+Shift+I.
KWC kwin KrohnkiteDecrease "Meta+Shift+I,none,Krohnkite: Decrease"
# Set Master: Krohnkite ships Meta+Return, but Hyprland (and dwm/i3/sway convention) uses
# Mod+Return to spawn a terminal. Terminal wins; Set Master moves to Meta+Shift+Return.
KWC kwin KrohnkiteSetMaster "Meta+Shift+Return,none,Krohnkite: Set master"
# KrohnkiteTileLayout (Meta+T) and KrohnkiteFocusLeft/Right/Up/Down/MoveLeft/Right/Up/Down
# and the resize quartet (Meta+Ctrl+HJKL) already match Hyprland's own scheme out of the box
# - no changes needed there.

echo "==> Native KWin: freeing/claiming keys, without evicting Plasma-native features"
# Edit Tiles (KWin's own quick-tile-zone editor) is redundant once Krohnkite owns tiling,
# and it collides literally with KrohnkiteTileLayout on Meta+T. Disable it.
KWC kwin "Edit Tiles" "none,Meta+T,Toggle Tiles Editor"
# Window Fullscreen had no default; Hyprland's SUPER+F was "force fullscreen".
KWC kwin "Window Fullscreen" "Meta+F,none,Make Window Fullscreen"
# Window Close: Meta+W is the primary (matching Hyprland's SUPER+W), Alt+F4 kept as a
# fallback. Overview moves off Meta+W to Meta+Shift+W so it isn't lost.
KWC kwin "Window Close" "Meta+W	Alt+F4,Alt+F4,Close Window"
KWC kwin "Overview" "Meta+Shift+W,Meta+W,Toggle Overview"
# Move the focused window to the other monitor (closest thing to Hyprland's
# movecurrentworkspacetomonitor - KWin desktops aren't per-monitor so there's no real
# equivalent, this just moves the active window). Meta+Shift+Left/Right dropped - unused.
KWC kwin "Window to Next Screen" "Ctrl+Alt+Right,Meta+Shift+Right,Move Window to Next Screen"
KWC kwin "Window to Previous Screen" "Ctrl+Alt+Left,Meta+Shift+Left,Move Window to Previous Screen"
# Lock Session's Meta+L silently collided with KrohnkiteFocusRight (also Meta+L) - whichever
# grabbed the chord first won, which made Super+L lock instead of focus-right. Drop Meta+L
# from Lock Session; the hardware Screensaver key still locks the session.
KWC ksmserver "Lock Session" "Screensaver,Screensaver	Meta+L,Lock Session"
# Window Maximize stays on Meta+PgUp; add Alt+F11 (Hyprland's "fullscreen 1" / maximize key).
KWC kwin "Window Maximize" "Meta+PgUp	Alt+F11,Meta+PgUp,Maximize Window"
# Klipper's "show clipboard at mouse" sits on Meta+V by default, which we just gave to
# Krohnkite's floating toggle. Move it to Meta+O (Hyprland's SUPER+O was its clipboard picker).
KWC plasmashell "show-on-mouse-pos" "Meta+O,Meta+V,Show Clipboard Items at Mouse Position"
# Browser wants bare Meta+B (exact Hyprland parity); evict the native "Switch Power Profile"
# shortcut from Meta+B, keeping it reachable via the hardware Battery key only.
KWC org_kde_powerdevil powerProfile "Battery,Battery	Meta+B,Switch Power Profile"

echo "==> Virtual desktops: 10, matching Hyprland's SUPER+[0-9] workspace scheme"
KWINC Desktops Number 10
KWINC Desktops Rows 1
# Reclaim bare Meta+1..9 from the taskbar "activate task manager entry N" feature (literal
# key collision, can't coexist) - Meta+0 for entry 10 was already unbound.
for i in 1 2 3 4 5 6 7 8 9; do
  KWC plasmashell "activate task manager entry $i" "none,Meta+$i,Activate Task Manager Entry $i"
done
# Switch to Desktop 1-4 already have Ctrl+F1-4 / Meta+F1-4; append Meta+1..4 as well.
KWC kwin "Switch to Desktop 1" "Ctrl+F1	Meta+F1	Meta+1,Ctrl+F1	Meta+F1,Switch to Desktop 1"
KWC kwin "Switch to Desktop 2" "Ctrl+F2	Meta+F2	Meta+2,Ctrl+F2	Meta+F2,Switch to Desktop 2"
KWC kwin "Switch to Desktop 3" "Ctrl+F3	Meta+F3	Meta+3,Ctrl+F3	Meta+F3,Switch to Desktop 3"
KWC kwin "Switch to Desktop 4" "Ctrl+F4	Meta+F4	Meta+4,Ctrl+F4	Meta+F4,Switch to Desktop 4"
for i in 5 6 7 8 9; do
  KWC kwin "Switch to Desktop $i" "Meta+$i,none,Switch to Desktop $i"
done
KWC kwin "Switch to Desktop 10" "Meta+0,none,Switch to Desktop 10"
# Window to Desktop N (move active window) had no defaults at all - bind Meta+Shift+[1-0].
#
# NOT "Meta+Shift+<digit>" as a literal string: physically pressing Shift+1 produces the
# keysym for "!", not "Key_1 with a Shift flag" - KWin's live grab matches the real keysym,
# so a binding written as Meta+Shift+1 can never fire; it listens for an event that doesn't
# exist. Bind to the actual produced symbol instead. (This is why the old Hyprland config
# used bindd = ... code:10 - raw keycode - for the equivalent binds; KDE's global shortcuts
# have no raw-keycode equivalent, so symbols it is. These are US QWERTY shift-level-2 symbols
# - if you're on the "tr" layout when you press this, the produced symbol may differ and the
# binding won't match; there's no single string that works across both layouts.)
declare -A desktop_shift_symbol=( [1]="!" [2]="@" [3]="#" [4]='$' [5]="%" [6]="^" [7]="&" [8]="*" [9]="(" [0]=")" )
for i in 1 2 3 4 5 6 7 8 9 0; do
  n=$i; [[ "$i" == "0" ]] && n=10
  KWC kwin "Window to Desktop $n" "Meta+${desktop_shift_symbol[$i]},none,Window to Desktop $n"
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.doRegister "['kwin', 'Window to Desktop $n', 'KWin', 'Window to Desktop $n']" >/dev/null 2>&1 || true
done

echo "==> Mouse: drag-move/resize anywhere on a window with Meta (was Alt), matching bindm"
KWINC MouseBindings CommandAllKey Meta

echo "==> Disabling the slide animation on virtual-desktop switch (too slow, Hyprland's was instant)"
KWINC Plugins slideEnabled false

echo "==> Input niceties: repeat rate/delay, numlock, focus-follows-mouse, keyboard layout"
INC Keyboard RepeatRate 35
INC Keyboard RepeatDelay 250
INC Keyboard NumLock 0
KWINC Windows FocusPolicy FocusFollowsMouse
# Unset, KWin's compiled-in default delay felt sluggish next to Hyprland's instant follow_mouse=1.
KWINC Windows DelayFocusInterval 0
XKB Layout Use true
XKB Layout LayoutList "us,tr"
XKB Layout Options "compose:caps,ctrl:nocaps,grp:alts_toggle"

echo "==> App-launcher shortcuts: generating .desktop + global-shortcut entries"
mkdir -p ~/.local/share/applications

make_launcher() {
  local id="$1" name="$2" exec="$3" shortcut="$4"
  local desktop="hypr-port-${id}.desktop"
  cat >"$HOME/.local/share/applications/${desktop}" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Exec=${exec}
NoDisplay=true
Terminal=false
X-KDE-GlobalAccel-CommandShortcut=true
EOF
  KWC "$desktop" _launch "${shortcut},none,${name}"
}

make_launcher terminal        "Terminal"             "launch-terminal"                                                              "Meta+Return"
make_launcher filemanager     "File Manager"         "dolphin"                                                                      "Meta+Alt+F"
make_launcher browser         "Browser"              "launch-browser"                                                               "Meta+B"
make_launcher activity        "Activity (btop)"      "launch-with-terminal btop"                                                    "Meta+Alt+T"
make_launcher claude          "Claude"               "launch-or-focus-webapp Claude https://claude.ai/new"                          "Meta+Alt+A"
make_launcher github          "GitHub"               "launch-or-focus-webapp GitHub https://github.com/OmerBilgin21"               "Meta+Alt+G"
make_launcher crunchyroll     "Crunchyroll"          "launch-or-focus-webapp Crunchyroll https://www.crunchyroll.com/discover"      "Meta+C"
make_launcher youtube         "YouTube"              "launch-or-focus-webapp YouTube https://youtube.com/"                          "Meta+Y"
make_launcher whatsapp        "WhatsApp"             "launch-or-focus-webapp WhatsApp https://web.whatsapp.com/"                    "Alt+W"
make_launcher netflix         "Netflix"              "launch-or-focus-webapp Netflix https://www.netflix.com/browse"                "Meta+N"
make_launcher rofi-drun       "App Launcher (rofi)"  "/bin/sh -c 'pkill rofi || rofi -show drun'"                                   "Meta+Space"
make_launcher rofimoji        "Emoji Picker"         "rofimoji --action=copy"                                                       "Meta+Shift+E"
make_launcher rofi-calc       "Calculator (rofi)"    "/bin/sh -c \"rofi -show calc -modi calc -no-show-match -no-sort -calc-command 'echo -n {result} | wl-copy'\"" "Meta+Shift+C"

echo "==> Session environment: \$TERMINAL/\$EDITOR aren't exported outside zsh under Plasma"
mkdir -p ~/.config/plasma-workspace/env
cat >~/.config/plasma-workspace/env/hypr-port.sh <<'EOF'
export TERMINAL=foot
export EDITOR=nvim
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
chmod +x ~/.config/plasma-workspace/env/hypr-port.sh

echo "==> Refreshing caches and reloading KWin/kglobalaccel"
kbuildsycoca6 >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
kquitapp6 kglobalaccel >/dev/null 2>&1 || true
sleep 1
kstart6 kglobalaccel >/dev/null 2>&1 &

echo
echo "Done. A few things need a full logout/login to fully take effect:"
echo "  - the 10 virtual desktops (System Settings may need a nudge otherwise)"
echo "  - the us,tr keyboard layout list + alts_toggle switch option"
echo "  - \$TERMINAL/\$EDITOR for the new launcher shortcuts (plasma-workspace/env is read at session start)"
