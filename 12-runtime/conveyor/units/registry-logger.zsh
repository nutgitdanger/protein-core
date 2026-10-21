#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

ROOT="$HOME/.config/dynu-audit"
REGISTRY_FILE="$ROOT/control/artifact-registry.tsv"

event_type="${1:-UNKNOWN}"       # เช่น FILE, NETWORK, NEURAL
target_id="${2:-none}"           # Path หรือ Job ID
sha_val="${3:-none}"             # SHA-256 ประจำตัว
method_route="${4:-default}"     # Route หรือ Method ที่ใช้
status="${5:-REGISTERED}"        # สถานะ เช่น SUCCESS, CACHE_HIT, PROCESSED

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

# บันทึกแถวใหม่ลงสมุดบันทึกกลาง (TSV Format)
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$timestamp" \
  "$event_type" \
  "$target_id" \
  "$sha_val" \
  "$method_route" \
  "$status" >> "$REGISTRY_FILE"

printf 'REGISTRY_LOG_UPDATED: %s [%s]\n' "$target_id" "$event_type"
