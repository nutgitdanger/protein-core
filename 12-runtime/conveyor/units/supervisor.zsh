#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
C="$ROOT/protein/12-runtime/conveyor"
U="$C/units"
STATE_FILE="$ROOT/protein/12-runtime/state/folding.state"
STATE="$C/state"
PIDFILE="$STATE/supervisor.pid"
LOCK="$STATE/supervisor.lock"
LOG="$STATE/supervisor.log"

mkdir -p "$STATE"

if ! mkdir "$LOCK" 2>/dev/null; then
  printf 'ERROR=SUPERVISOR_ALREADY_RUNNING\n'
  exit 1
fi

cleanup() {
  trap - INT TERM HUP EXIT
  rm -f "$PIDFILE"
  rmdir "$LOCK" 2>/dev/null
  printf '%s SUPERVISOR_STOPPED\n' "$(date -u +%Y%m%dT%H%M%SZ)" >> "$LOG"
}

trap cleanup INT TERM HUP EXIT

printf '%s\n' "$$" > "$PIDFILE.tmp.$$"
mv -f "$PIDFILE.tmp.$$" "$PIDFILE"

last_sha=""

printf '%s SUPERVISOR_STARTED PID=%s\n' \
  "$(date -u +%Y%m%dT%H%M%SZ)" "$$" >> "$LOG"

while :; do
  if [[ ! -r "$STATE_FILE" ]]; then
    printf '%s ERROR=STATE_MISSING\n' \
      "$(date -u +%Y%m%dT%H%M%SZ)" >> "$LOG"
    sleep 30
    continue
  fi

  current_sha="$(sha256sum "$STATE_FILE" | awk '{print $1}')"

  if [[ "$current_sha" != "$last_sha" ]]; then
    printf '%s STATE=%s\n' \
      "$(date -u +%Y%m%dT%H%M%SZ)" "$current_sha" >> "$LOG"

    JOB_ID="folding-$current_sha"
    JOB_FILE="$C/jobs/$JOB_ID.job"

    mkdir -p "$C/jobs"

    CREATED="$(date -u +%Y%m%dT%H%M%SZ)"
    CREATE_RC=0
    "$C/units/job-create.zsh" "$JOB_FILE" "$current_sha" "folding" "canonical" "none" "1" "$CREATED" "$STATE_FILE" >/dev/null 2>&1 || CREATE_RC=$?
    if [[ "$CREATE_RC" -ne 0 && "$CREATE_RC" -ne 4 ]]; then
      printf '%s JOB_CREATE_RC=%s JOB_ID=%s\n' "$CREATED" "$CREATE_RC" "$JOB_ID" >> "$LOG"
      continue
    fi

    "$U/evaluate.zsh" "$JOB_ID" >> "$LOG" 2>&1
    EVAL_RC=$?

    printf '%s EVALUATE_RC=%s JOB_ID=%s\n'       "$(date -u +%Y%m%dT%H%M%SZ)" "$EVAL_RC" "$JOB_ID" >> "$LOG"

    if [[ "$EVAL_RC" -eq 0 ]]; then
      last_sha="$current_sha"
    fi
  fi

  sleep 30
done
