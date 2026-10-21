#!/bin/bash
# Protein System: Autonomous Governor & Decision Engine
CONFIG_DIR="$HOME/.config/dynu-audit"
cd "$CONFIG_DIR"

echo "====================================================="
echo "       🧬 PROTEIN ECOSYSTEM — AUTONOMOUS GOVERNOR"
echo "====================================================="

# สร้างโฟลเดอร์รองรับหากยังไม่มี
mkdir -p state reports

# ตรวจสอบความสมบูรณ์และจัดการสถานะเบื้องต้น
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="state/governor-$TIMESTAMP.log"

{
  echo "Governor Execution Log - $TIMESTAMP"
  echo "----------------------------------------"
  
  # ตรวจสอบไฟล์ตกค้างหรือข้อผิดพลาด
  broken_links=$(find . -maxdepth 1 -type l ! -exec test -e {} \; -print)
  if [ -n "$broken_links" ]; then
    echo "[!] Found broken symlinks:"
    echo "$broken_links"
  else
    echo "[+] All system symlinks are healthy."
  fi

  # ตรวจสอบสิทธิ์การรันของสคริปต์ทั้งหมด
  echo "[+] Verifying molecule executable permissions..."
  find . -maxdepth 1 -name "protein-*.sh" ! -executable -exec echo "[!] Non-executable: {}" \;

} | tee "$LOG_FILE"

echo "====================================================="
echo "       GOVERNOR CYCLE COMPLETE. REPORT SAVED."
echo "====================================================="
