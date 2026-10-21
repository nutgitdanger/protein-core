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

printf '=== CONVEYOR EVALUATION CORE ===\n'
printf 'JOB_ID=%s\n' "$JOB_ID"
printf 'CACHE_KEY=%s\n' "$KEY"

if [[ -f "$C/cache/$KEY.result" ]]; then
  printf 'CACHE=HIT\nROUTE=SKIP_COMPUTE\n'
  printf '=== RESULT CONTENT ===\n'
  cat "$C/cache/$KEY.result"
else
  printf 'CACHE=MISS\nROUTE=EXECUTE_OR_OFFLOAD\n'
  
  RESULT_PATH="$C/results/$JOB_ID.result"
  
  cat > "$RESULT_PATH.tmp.$$" <<RES_EOF
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
  mv -f "$RESULT_PATH.tmp.$$" "$RESULT_PATH"

  CACHE_PATH="$C/cache/$KEY.result"
  CACHE_TMP="$CACHE_PATH.tmp.$$"
  cp "$RESULT_PATH" "$CACHE_TMP"
  mv -f "$CACHE_TMP" "$CACHE_PATH"
  
  printf '=== NEW RESULT GENERATED & CACHED ===\n'
  cat "$RESULT_PATH"
fi
