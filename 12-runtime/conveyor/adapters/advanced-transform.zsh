#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

raw_input="${1:-}"
method="${2:-generic}"

if [[ -z "$raw_input" ]]; then
  printf 'STATUS=REJECT\nREASON=EMPTY_INPUT\n'
  exit 1
fi

# 1. RAW & NORMALIZE
cleaned="$(printf '%s' "$raw_input" | tr '[:upper:]' '[:lower:]' | xargs)"
val="$(printf '%s' "$cleaned" | grep -oE '^[0-9\.]+' || printf '0')"
unit="$(printf '%s' "$cleaned" | sed -E 's/^[0-9\.]+ *//')"

norm_val="$val"
norm_unit="$unit"
type="scalar"

# 2. MULTI-UNIT CONVERSION ENGINE (Network / Storage / Frequency)
case "$unit" in
  gbps)
    norm_val=$(( val * 1000000000 ))
    norm_unit="bit/s"
    type="network_rate"
    ;;
  mbps)
    norm_val=$(( val * 1000000 ))
    norm_unit="bit/s"
    type="network_rate"
    ;;
  kbps)
    norm_val=$(( val * 1000 ))
    norm_unit="bit/s"
    type="network_rate"
    ;;
  gb|gigabyte|gbits)
    norm_val=$(( val * 1024 * 1024 * 1024 ))
    norm_unit="bytes"
    type="storage_size"
    ;;
  mb|megabyte|mbits)
    norm_val=$(( val * 1024 * 1024 ))
    norm_unit="bytes"
    type="storage_size"
    ;;
  rpm|hz)
    norm_val="$val"
    norm_unit="$unit"
    type="frequency"
    ;;
  *)
    type="scalar"
    ;;
esac

# 3. GENERATE IDENTITY SHA (AXIS 1)
payload="type=$type|val=$norm_val|unit=$norm_unit"
input_sha="$(printf '%s' "$payload" | sha256sum | awk '{print $1}')"

# 4. READY OUTPUT (พร้อมส่งเข้า Conveyor & Engine)
printf 'RAW=%s\n' "$raw_input"
printf 'TYPE=%s\n' "$type"
printf 'VALUE=%s\n' "$norm_val"
printf 'UNIT=%s\n' "$norm_unit"
printf 'INPUT_SHA256=%s\n' "$input_sha"
printf 'STATUS=READY\n'
