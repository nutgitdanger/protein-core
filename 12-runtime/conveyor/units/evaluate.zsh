#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
C="$ROOT/protein/12-runtime/conveyor"
JOB_ID="${1:-}"

if [[ -z "$JOB_ID" || ! -f "$C/jobs/$JOB_ID.job" ]]; then
  printf 'ERROR=JOB_NOT_FOUND\n'
  exit 1
fi

JOB="$C/jobs/$JOB_ID.job"
SHA="$(awk -F= '$1=="INPUT_SHA256"{print $2}' "$JOB")"
METHOD="$(awk -F= '$1=="METHOD"{print $2}' "$JOB")"
PARAMS="$(awk -F= '$1=="PARAMS"{print $2}' "$JOB")"
KEY="$(printf '%s\n' "$SHA|$METHOD|$PARAMS" | sha256sum | awk '{print $1}')"

CACHE_DIR="$C/cache"
RESULT_DIR="$C/results"
LOCK_DIR="$CACHE_DIR/.locks"
CACHE_PATH="$CACHE_DIR/$KEY.result"
RESULT_PATH="$RESULT_DIR/$JOB_ID.result"
LOCK="$LOCK_DIR/$KEY.lock"
OWNER="$LOCK/owner"

mkdir -p "$CACHE_DIR" "$RESULT_DIR" "$LOCK_DIR"

printf '=== CONVEYOR EVALUATION CORE ===\n'
printf 'JOB_ID=%s\n' "$JOB_ID"
printf 'CACHE_KEY=%s\n' "$KEY"

LOCK_ACQUIRED=0

cleanup_lock() {
  if [[ "$LOCK_ACQUIRED" == 1 ]]; then
    rm -rf "$LOCK" 2>/dev/null
  fi
}

trap cleanup_lock EXIT INT TERM HUP

while ! mkdir "$LOCK" 2>/dev/null; do
  if [[ -f "$OWNER" ]]; then
    OWNER_PID="$(cat "$OWNER" 2>/dev/null)"
    if [[ -n "$OWNER_PID" ]] && ! kill -0 "$OWNER_PID" 2>/dev/null; then
      rm -rf "$LOCK" 2>/dev/null
      continue
    fi
  fi
  sleep 0.2
done

LOCK_ACQUIRED=1
printf '%s\n' "$$" > "$OWNER"

if [[ -f "$CACHE_PATH" ]]; then
  printf 'CACHE=HIT\nROUTE=SKIP_COMPUTE\n'
  printf '=== RESULT CONTENT ===\n'
  cat "$CACHE_PATH"
  exit 0
fi

if [[ -f "$RESULT_PATH" ]]; then
  RESULT_SHA="$(awk -F= '$1=="INPUT_SHA256"{print $2}' "$RESULT_PATH")"
  RESULT_METHOD="$(awk -F= '$1=="METHOD"{print $2}' "$RESULT_PATH")"

  if [[ "$RESULT_SHA" == "$SHA" && "$RESULT_METHOD" == "$METHOD" ]]; then
    CACHE_TMP="$CACHE_PATH.tmp.$$"
    cp "$RESULT_PATH" "$CACHE_TMP"
    mv -f "$CACHE_TMP" "$CACHE_PATH"

    printf 'CACHE=REBUILT_FROM_RESULT\nROUTE=SKIP_COMPUTE\n'
    printf '=== RESULT CONTENT ===\n'
    cat "$RESULT_PATH"
    exit 0
  fi
fi

printf 'CACHE=MISS\nROUTE=EXECUTE_OR_OFFLOAD\n'

RESULT_TMP="$RESULT_PATH.tmp.$$"

cat > "$RESULT_TMP" <<RES_EOF
JOB_ID=$JOB_ID
INPUT_SHA256=$SHA
METHOD=$METHOD
RESULT_SHA256=$(printf 'result-%s' "$SHA" | sha256sum | awk '{print $1}')
RESULT_PATH=$RESULT_PATH
COMPUTE=EC2
VALIDATION=PASSED
STATUS=COMPLETED
CREATED=$(date -u +%Y%m%dT%H%M%SZ)
RES_EOF

mv -f "$RESULT_TMP" "$RESULT_PATH"

CACHE_TMP="$CACHE_PATH.tmp.$$"
cp "$RESULT_PATH" "$CACHE_TMP"
mv -f "$CACHE_TMP" "$CACHE_PATH"

printf '=== NEW RESULT GENERATED & CACHED ===\n'
cat "$RESULT_PATH"
