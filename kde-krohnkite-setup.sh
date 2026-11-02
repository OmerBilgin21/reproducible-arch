#!/usr/bin/env bash
#
# Ports the keybinds/niceties from config-linux/hypr/ (Hyprland) onto the new
# Plasma 6 + Krohnkite 0.9.9.2 setup. Idempotent.
#
# What it deliberately overrides vs. Krohnkite/KWin's shipped defaults, and why,
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
# Related but distinct gotcha: if the .desktop files get deleted (accidentally, e.g. a stray
# `rm hypr-port-*.desktop`), kglobalaccel drops the component from its live registry entirely -
# recreating the file + kbuildsycoca6 is NOT enough to bring it back on its own; it needs an
# explicit doRegister() call, which make_launcher() now does unconditionally (harmless no-op
# if the component's already registered).

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
# Toggle Float All freed up to give its Meta+Shift+F to Window Fullscreen below - unused.
KWC kwin KrohnkiteFloatAll "none,none,Krohnkite: Toggle Float All"

echo "==> Native KWin: freeing/claiming keys, without evicting Plasma-native features"
# Edit Tiles (KWin's own quick-tile-zone editor) is redundant once Krohnkite owns tiling,
# and it collides literally with KrohnkiteTileLayout on Meta+T. Disable it.
KWC kwin "Edit Tiles" "none,Meta+T,Toggle Tiles Editor"
# Window Fullscreen had no default; Hyprland's SUPER+F was "force fullscreen". Moved off
# Meta+F to Meta+Shift+F so Meta+F is free for the file manager launcher below.
KWC kwin "Window Fullscreen" "Meta+Shift+F,none,Make Window Fullscreen"
# Activities switcher freed up to give its Meta+A to the Claude launcher below - you're not
# running multiple Activities, just virtual desktops, so this was a dead shortcut anyway.
KWC plasmashell "next activity" "none,none,Walk through activities"
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
# Writing "Meta+!" to kglobalshortcutsrc and calling doRegister is NOT enough - KDE
# re-displays "Meta+!" as "Meta+Shift+1" (same canonical QKeySequence either way) but the
# live compositor grab never actually updates from an ini-write + doRegister for an action
# that already has a registered (even if non-functional) shortcut. The only thing that
# reliably pushes a live grab is calling setForeignShortcut with the actual Qt key integer -
# this is what System Settings' own Apply button does under the hood. Qt's key enum mirrors
# ASCII for printable punctuation, so the integer is just (Meta modifier) + (ascii code).
declare -A desktop_shift_symbol=([1]="!" [2]="@" [3]="#" [4]='$' [5]="%" [6]="^" [7]="&" [8]="*" [9]="(" [0]=")")
for i in 1 2 3 4 5 6 7 8 9 0; do
  n=$i
  [[ "$i" == "0" ]] && n=10
  s="${desktop_shift_symbol[$i]}"
  key=$((0x10000000 + $(printf '%d' "'$s")))
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.setForeignShortcut \
    "['kwin', 'Window to Desktop $n', 'KWin', 'Window to Desktop $n']" "[$key]" >/dev/null
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
  # kglobalaccel doesn't pick up a (re)created command-shortcut component just from
  # kbuildsycoca6 - if the .desktop file was ever deleted (e.g. by `rm hypr-port-*.desktop`),
  # the component vanishes from kglobalaccel's live registry and doRegister is what brings
  # it back. Harmless no-op if the component was already registered.
  gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
    --method org.kde.KGlobalAccel.doRegister \
    "['$desktop', '$name', '_launch', '$name']" >/dev/null
}

make_launcher terminal "Terminal" "launch-terminal" "Meta+Return"
make_launcher filemanager "File Manager" "dolphin" "Meta+F"
make_launcher browser "Browser" "launch-browser" "Meta+B"
make_launcher activity "Activity (btop)" "launch-with-terminal btop" "Meta+Alt+T"
make_launcher claude "Claude" "launch-webapp https://claude.ai/new" "Meta+A"
make_launcher github "GitHub" "launch-webapp https://github.com/OmerBilgin21" "Meta+Alt+G"
make_launcher crunchyroll "Crunchyroll" "launch-webapp https://www.crunchyroll.com/discover" "Meta+C"
make_launcher youtube "YouTube" "launch-webapp https://youtube.com/" "Meta+Y"
make_launcher whatsapp "WhatsApp" "launch-webapp https://web.whatsapp.com/" "Alt+W"
make_launcher netflix "Netflix" "launch-webapp https://www.netflix.com/browse" "Meta+N"
make_launcher rofi-drun "App Launcher (rofi)" "/bin/sh -c 'pkill rofi || rofi -show drun'" "Meta+Space"
make_launcher rofimoji "Emoji Picker" "rofimoji --action=copy" "Meta+Shift+E"
make_launcher rofi-calc "Calculator (rofi)" "cmd-rofi-calc" "Meta+Shift+C"

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

echo "==> Window rules: no titlebar/frame for foot, wezterm, Brave (+ its webapps), Steam"
# kwinrulesrc notes (reverse-engineered live, not documented anywhere):
# - Writing the "obvious" noborder/noborderrule keys gets silently rewritten by KWin into
#   decorationpolicy=none / decorationpolicyrule=<n> on next read - write the new names directly.
# - decorationpolicyrule=3 is Force (continuous reapply); it only takes effect at window
#   *creation* though - it does not retroactively strip the border off windows already open
#   when the rule was added. Close/reopen (or just wait for the next natural relaunch).
# - wmclasscomplete=false matches against resourceClass ONLY (not resourceName, despite what
#   the name suggests) - wmclassmatch: 1=Exact, 2=Substring.
# - Brave's main window is class "brave-origin", but each --app= webapp window gets its own
#   class like "brave-<domain>__<path>-Default" (resourceName is "brave" for all of them, but
#   wmclasscomplete=false does NOT match on resourceName - don't bother trying that route).
#   A Substring match on "brave" against resourceClass catches every one of them in one rule.
# - KWin can auto-generate its own "Application settings for <app>" rule (e.g. after a manual
#   per-window decoration toggle) that's ordered *before* these and can silently shadow them
#   for the same property. If a rule below mysteriously stops applying, check for a stray
#   UUID-named group in kwinrulesrc ahead of these in [General] Order.
KWRULE() { kwriteconfig6 --file kwinrulesrc --group "$1" --key "$2" "$3"; }

KWRULE hypr-port-noframe-foot Description "foot - no titlebar/frame"
KWRULE hypr-port-noframe-foot decorationpolicy none
KWRULE hypr-port-noframe-foot decorationpolicyrule 3
KWRULE hypr-port-noframe-foot types 1
KWRULE hypr-port-noframe-foot wmclass foot
KWRULE hypr-port-noframe-foot wmclasscomplete false
KWRULE hypr-port-noframe-foot wmclassmatch 1

KWRULE hypr-port-noframe-wezterm Description "wezterm - no titlebar/frame"
KWRULE hypr-port-noframe-wezterm decorationpolicy none
KWRULE hypr-port-noframe-wezterm decorationpolicyrule 3
KWRULE hypr-port-noframe-wezterm types 1
KWRULE hypr-port-noframe-wezterm wmclass "org.wezfurlong.wezterm"
KWRULE hypr-port-noframe-wezterm wmclasscomplete false
KWRULE hypr-port-noframe-wezterm wmclassmatch 1

KWRULE hypr-port-noframe-brave Description "Brave + webapps - no titlebar/frame"
KWRULE hypr-port-noframe-brave decorationpolicy none
KWRULE hypr-port-noframe-brave decorationpolicyrule 3
KWRULE hypr-port-noframe-brave types 1
KWRULE hypr-port-noframe-brave wmclass brave
KWRULE hypr-port-noframe-brave wmclasscomplete false
KWRULE hypr-port-noframe-brave wmclassmatch 2

KWRULE hypr-port-noframe-steam Description "Steam - no titlebar/frame"
KWRULE hypr-port-noframe-steam decorationpolicy none
KWRULE hypr-port-noframe-steam decorationpolicyrule 3
KWRULE hypr-port-noframe-steam types 1
KWRULE hypr-port-noframe-steam wmclass steam
KWRULE hypr-port-noframe-steam wmclasscomplete false
KWRULE hypr-port-noframe-steam wmclassmatch 1

# Add our 4 rules to [General] Order without clobbering anything already there (other
# manually-added rules, or a KWin auto-generated one) - just dedupe-append.
current_order="$(kreadconfig6 --file kwinrulesrc --group General --key Order 2>/dev/null || true)"
IFS=',' read -ra order_parts <<<"$current_order"
for id in hypr-port-noframe-foot hypr-port-noframe-wezterm hypr-port-noframe-brave hypr-port-noframe-steam; do
  found=0
  for part in "${order_parts[@]}"; do
    [[ "$part" == "$id" ]] && found=1 && break
  done
  [[ $found -eq 0 ]] && order_parts+=("$id")
done
new_order="$(
  IFS=,
  echo "${order_parts[*]}"
)"
kwriteconfig6 --file kwinrulesrc --group General --key Order --type string "$new_order"

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
