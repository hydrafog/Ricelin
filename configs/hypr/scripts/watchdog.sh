#!/bin/sh
name="$1"
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/${name}-watchdog.lock"
flock -n 9 || exit 0

launch() {
  qs -c "$name" -d 9>&- 2>/dev/null
  i=0
  while [ "$i" -lt 30 ]; do
    qs -c "$name" ipc show >/dev/null 2>&1 && return
    sleep 1
    i=$((i + 1))
  done
}

while true; do
  qs -c "$name" ipc show >/dev/null 2>&1 || launch
  sleep 5
done

