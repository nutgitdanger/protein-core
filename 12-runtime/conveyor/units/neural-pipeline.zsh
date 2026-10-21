#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
C="$ROOT/protein/12-runtime/conveyor"

raw_input="${1:-100000000}"
method="neural_routing"
model_id="neural_v1_matrix"

# 1. รัน Neural Core
neural_output="$("$C/adapters/neural-core.zsh" "$raw_input" "network_rate")"
sha="$(printf '%s\n' "$neural_output" | grep '^NEURAL_SHA256=' | cut -d= -f2)"
route="$(printf '%s\n' "$neural_output" | grep '^ROUTE=' | cut -d= -f2)"

if [[ -z "$sha" ]]; then
  printf 'ERROR=NEURAL_SHA_FAILED\n'
  exit 1
fi

# 2. คำนวณ Compute Key
relation_ref="network_to_core_dag"
relation_hash="$(printf '%s' "$relation_ref" | sha256sum | awk '{print $1}')"
compute_key="$(printf '%s|%s|%s' "$sha" "$relation_hash" "$model_id" | sha256sum | awk '{print $1}')"

result_file="$C/cache/$compute_key.result"

# 3. เช็ก Cache พร้อมบันทึกลงสมุดบันทึกกลาง (Registry)
if [[ -f "$result_file" ]]; then
  status_type="CACHE_HIT"
  "$C/units/registry-logger.zsh" "NEURAL_PIPELINE" "input-$raw_input" "$sha" "$route" "$status_type"
  printf 'CACHE=HIT\nROUTE=SKIP_COMPUTE (Using cached neural decision)\n'
else
  status_type="CACHE_MISS"
  cat > "$result_file.tmp.$$" <<RES_EOF
  mv -f "$result_file.tmp.$$" "$result_file"
INPUT_SHA256=$sha
COMPUTE_KEY=$compute_key
MODEL=$model_id
STATUS=PROCESSED_AND_CACHED
CREATED=$(date -u +%Y%m%dT%H%M%SZ)
RES_EOF
  "$C/units/registry-logger.zsh" "NEURAL_PIPELINE" "input-$raw_input" "$sha" "$route" "$status_type"
  printf 'CACHE=MISS\nROUTE=EXECUTE_NEW_NEURAL_STATE\n'
fi
