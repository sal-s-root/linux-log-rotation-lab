#!/usr/bin/env bash
set -euo pipefail
lab_dir=$1
sequence=0
reopen() { exec 3>> "$lab_dir/app.log"; printf 'reopened\n' >> "$lab_dir/events.log"; }
stop() {
  exec 3>&-
  printf '%s\n' "$sequence" > "$lab_dir/final-sequence"
  exit 0
}
trap reopen HUP
trap stop TERM INT
exec 3>> "$lab_dir/app.log"
while :; do
  sequence=$((sequence+1))
  printf '%s\n' "$sequence" >&3
  sleep 0.02
done
