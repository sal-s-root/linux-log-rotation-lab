#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
command -v logrotate >/dev/null
command -v gzip >/dev/null
umask 077
lab_dir=$(mktemp -d)
logger_pid=''
cleanup() {
  if [[ -n $logger_pid ]]; then kill -TERM "$logger_pid" 2>/dev/null || true; wait "$logger_pid" 2>/dev/null || true; fi
  rm -rf -- "$lab_dir"
}
trap cleanup EXIT
wait_for_log() {
  for ((i=0; i<200; i++)); do
    if [[ -s $lab_dir/app.log ]]; then return 0; fi
    sleep 0.02
  done
  echo 'log writer did not reopen the active file' >&2; return 1
}
bash logger.sh "$lab_dir" & logger_pid=$!
wait_for_log
cat > "$lab_dir/rotation.conf" <<CONFIG
"$lab_dir/app.log" {
    daily
    rotate 2
    compress
    delaycompress
    missingok
    notifempty
    create 0600
    postrotate
        kill -HUP $logger_pid
    endscript
}
CONFIG
logrotate --state "$lab_dir/state" --force "$lab_dir/rotation.conf"
wait_for_log
[[ -s $lab_dir/app.log.1 && ! -e $lab_dir/app.log.1.gz ]]
printf 'PASS rename, creation, and delayed compression\n'
logrotate --state "$lab_dir/state" --force "$lab_dir/rotation.conf"
wait_for_log
[[ -s $lab_dir/app.log.2.gz && -s $lab_dir/app.log.1 ]]
kill -TERM "$logger_pid"; wait "$logger_pid"; logger_pid=''
[[ $(grep -c '^reopened$' "$lab_dir/events.log") == 2 ]]
gzip -dc "$lab_dir/app.log.2.gz" > "$lab_dir/combined"
cat "$lab_dir/app.log.1" "$lab_dir/app.log" >> "$lab_dir/combined"
final_sequence=$(cat "$lab_dir/final-sequence")
awk -v final="$final_sequence" 'BEGIN { expected=1 } { if (NF!=1 || $1!=expected) exit 1; expected++ } END { if (NR!=final) exit 1 }' "$lab_dir/combined"
printf 'PASS writer reopened twice and all %s sequence records were retained exactly once\n' "$final_sequence"
