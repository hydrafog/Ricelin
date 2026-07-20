#!/usr/bin/env bash
set -euo pipefail

flags_file="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin/flags.json"
WPDIR=$(jq -r '.wallpaperDir // ""' "$flags_file" 2>/dev/null || echo "")
[ -n "$WPDIR" ] || WPDIR="$HOME/Ricelin/wallpapers"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin-wallpaper"
BAG="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin-wallpaper-bag"

ensure_daemon() {
  awww query >/dev/null 2>&1 && return 0
  local attempt i
  for attempt in 1 2 3 4 5; do
    awww-daemon >/dev/null 2>&1 &
    for i in $(seq 1 15); do
      awww query >/dev/null 2>&1 && return 0
      sleep 0.2
    done
  done
  return 1
}

list_pics() {
  find "$WPDIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \)
}

refill_bag() {
  local current="" shuffled
  [ -r "$STATE" ] && current=$(cat "$STATE")
  shuffled=$(list_pics | shuf)
  [ -n "$shuffled" ] || return 0
  if [ "$(printf '%s\n' "$shuffled" | head -n1)" = "$current" ] && [ "$(printf '%s\n' "$shuffled" | wc -l)" -gt 1 ]; then
    shuffled=$(
      printf '%s\n' "$shuffled" | tail -n +2
      printf '%s\n' "$current"
    )
  fi
  mkdir -p "$(dirname "$BAG")"
  printf '%s\n' "$shuffled" >"$BAG"
}

pop_bag() {
  local line refilled=false
  mkdir -p "$(dirname "$BAG")"
  (
    flock 9
    while :; do
      if [ ! -s "$BAG" ]; then
        [ "$refilled" = true ] && exit 1
        refill_bag
        refilled=true
        [ -s "$BAG" ] || exit 1
      fi
      line=$(head -n1 "$BAG")
      tail -n +2 "$BAG" >"$BAG.tmp" && mv "$BAG.tmp" "$BAG"
      if [ -f "$line" ]; then
        printf '%s\n' "$line"
        exit 0
      fi
    done
  ) 9>"$BAG.lock"
}

daemon_was_running=true
awww query >/dev/null 2>&1 || daemon_was_running=false
ensure_daemon || exit 0

cmd="${1:-}"

if [ "$cmd" = "init" ]; then
  if [ -r "$STATE" ] && pic=$(cat "$STATE") && [ -f "$pic" ]; then
    :
  else
    pic=$(pop_bag) || exit 0
  fi

  # Always regenerate colours on init so the shell palette is correct from boot
  pmode=$(jq -r '.paletteMode // "static"' "$flags_file" 2>/dev/null || echo static)
  if [ "$pmode" = "manual" ]; then
    mh=$(jq -r '.manualHue // 30' "$flags_file" 2>/dev/null || echo 30)
    md=$(jq -r 'if .manualDark == false then "light" else "dark" end' "$flags_file" 2>/dev/null || echo dark)
    python3 "$(dirname "$0")/wallcolors.py" --hue "$mh" "$md" >/dev/null 2>&1 || true
  else
    python3 "$(dirname "$0")/wallcolors.py" "$pic" >/dev/null 2>&1 || true
  fi

  # If the daemon was already running the wallpaper is already set — no need to
  # re-apply a transition, just signal Ghostty to reload its colour file.
  if [ "$daemon_was_running" = true ]; then
    pkill -USR2 ghostty || true
    exit 0
  fi
elif [ "$cmd" = "set" ]; then
  pic="${2:-}"
  [ -f "$pic" ] || exit 1
else
  pic=$(pop_bag) || exit 0
fi

[ -n "$pic" ] || exit 0

pmode=$(jq -r '.paletteMode // "static"' "$flags_file" 2>/dev/null || echo static)
if [ "$pmode" = "manual" ]; then
  mh=$(jq -r '.manualHue // 30' "$flags_file" 2>/dev/null || echo 30)
  md=$(jq -r 'if .manualDark == false then "light" else "dark" end' "$flags_file" 2>/dev/null || echo dark)
  python3 "$(dirname "$0")/wallcolors.py" --hue "$mh" "$md" >/dev/null 2>&1 || true
else
  python3 "$(dirname "$0")/wallcolors.py" "$pic" >/dev/null 2>&1 || true
fi

awww img "$pic" \
  --transition-type wave \
  --transition-angle 30 \
  --transition-wave "60,30" \
  --transition-fps 60 \
  --transition-step 90 \
  --transition-duration 1.0

mkdir -p "$(dirname "$STATE")"
printf '%s\n' "$pic" >"$STATE"

sleep 0.15
# Update borders dynamically without full reload to prevent screen flashing/shader loss
hyprctl eval '
  local ok, wc = pcall(dofile, os.getenv("HOME") .. "/.cache/ricelin/hypr-colors.lua")
  if ok and wc then
    local c1 = wc.c1 or wc.active
    local c2 = wc.c2 or wc.inactive
    if c1 then c1 = "rgb(" .. c1:gsub("#", "") .. ")" end
    if c2 then c2 = "rgb(" .. c2:gsub("#", "") .. ")" end
    hl.config({
      general = {
        col = {
          active_border = { colors = { c1, c2 }, angle = 45 },
          inactive_border = { colors = { c1, c2 }, angle = 45 }
        }
      }
    })
  end
' >/dev/null 2>&1 || true
pkill -USR2 ghostty || true
pkill -USR2 btop || true

