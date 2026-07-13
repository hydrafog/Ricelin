#!/usr/bin/env bash
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/ricelin"
snap="$state/gamemode-snapshot.json"
mkdir -p "$state"

getint() { hyprctl getoption "$1" -j | jq -r '.int'; }
getbool() { hyprctl getoption "$1" -j | jq -r '.bool'; }
getgap() { hyprctl getoption "$1" -j | jq -r '.css' | awk '{ print $1 }'; }

strip() {
  hyprctl eval 'hl.config({ general = { gaps_in = 0, gaps_out = 0, border_size = 0 }, decoration = { rounding = 0, blur = { enabled = false }, shadow = { enabled = false } }, animations = { enabled = false } })' >/dev/null
}

case "${1:-}" in
on)
  if [ ! -f "$snap" ]; then
    jq -n \
      --arg gi "$(getgap general:gaps_in)" \
      --arg go "$(getgap general:gaps_out)" \
      --arg bs "$(getint general:border_size)" \
      --arg rd "$(getint decoration:rounding)" \
      --arg bl "$(getbool decoration:blur:enabled)" \
      --arg sh "$(getbool decoration:shadow:enabled)" \
      --arg an "$(getbool animations:enabled)" \
      '{gaps_in:$gi, gaps_out:$go, border_size:$bs, rounding:$rd, blur:$bl, shadow:$sh, anim:$an}' >"$snap"
  fi
  strip
  ;;
off)
  if [ -f "$snap" ]; then
    gi=$(jq -r '.gaps_in' "$snap")
    go=$(jq -r '.gaps_out' "$snap")
    bs=$(jq -r '.border_size' "$snap")
    rd=$(jq -r '.rounding' "$snap")
    bl=$(jq -r '.blur' "$snap")
    sh=$(jq -r '.shadow' "$snap")
    an=$(jq -r '.anim' "$snap")
    hyprctl eval "hl.config({ general = { gaps_in = $gi, gaps_out = $go, border_size = $bs }, decoration = { rounding = $rd, blur = { enabled = $bl }, shadow = { enabled = $sh } }, animations = { enabled = $an } })" >/dev/null
    rm -f "$snap"
  else
    current_shader=$(hyprshade current 2>/dev/null || echo "")
    hyprctl reload >/dev/null
    if [ -n "$current_shader" ]; then
      hyprshade on "$current_shader" >/dev/null 2>&1 || true
    fi
  fi
  ;;
*)
  echo "usage: gamemode.sh on|off" >&2
  exit 1
  ;;
esac

