#!/data/data/com.termux/files/usr/bin/zsh
setopt NO_BANG_HIST

# รับข้อมูลดิบเข้ามา (เช่น "100 Mbps", "53.0 mm", หรือข้อความทั่วไป)
raw_input="${1:-}"

if [[ -z "$raw_input" ]]; then
  printf 'ERROR=EMPTY_RAW_INPUT\n'
  exit 1
fi

# 1. RAW: แสดงข้อมูลดิบ
printf 'RAW=%s\n' "$raw_input"

# 2. PARSE & NORMALIZE: ทำความสะอาด ตัดช่องว่าง แปลงเป็นตัวพิมพ์เล็ก
cleaned="$(printf '%s' "$raw_input" | tr '[:upper:]' '[:lower:]' | xargs)"

# 3. TYPE & UNIT EXTRACTION: แยกตัวเลขและหน่วย (ตัวอย่างง่ายๆ)
# เช่น "100 mbps" -> value=100, unit=mbps
value="$(printf '%s' "$cleaned" | grep -oE '^[0-9\.]+' || printf '0')"
unit="$(printf '%s' "$cleaned" | sed -E 's/^[0-9\.]+ *//')"

# 4. MAP & VALIDATE: แปลงหน่วยมาตรฐาน (Normalize Unit)
normalized_value="$value"
normalized_unit="$unit"

if [[ "$unit" == "mbps" ]]; then
  # แปลง Mbps เป็น bit/s
  normalized_value=$(( (value * 1000000) ))
  normalized_unit="bit/s"
elif [[ "$unit" == "kbps" ]]; then
  normalized_value=$(( (value * 1000) ))
  normalized_unit="bit/s"
fi

# 5. READY OUTPUT: ข้อมูลพร้อมส่งเข้า Computational Core / Sensor Gate
printf 'TYPE=scalar\n'
printf 'VALUE=%s\n' "$normalized_value"
printf 'UNIT=%s\n' "$normalized_unit"
printf 'STATUS=READY\n'
