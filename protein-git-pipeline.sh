#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# Protein Core: Git-Integrated Local Automation Engine
# แปลงตรรกะสคริปต์เก่าให้มาทำงานกับเครื่องมือถือ ผูกเข้ากับระบบ Git อัตโนมัติ
# ==============================================================================

set -e

# กำหนดเส้นทางหลักของคลังโปรเจกต์ภายในเครื่อง
PROJECT_DIR="$HOME/projects/nutdata"
TARGET_REPO="${GIT_MAIN_REPO_DIR:-$PROJECT_DIR}"

echo "=========================================="
echo "  PROTEIN CORE: LOCAL-GIT AUTOMATION PIPELINE"
echo "=========================================="

# 1. ตรวจสอบและสร้างโฟลเดอร์โปรเจกต์หากยังไม่มี
if [ ! -d "$TARGET_REPO" ]; then
    echo "📂 กำลังสร้างโฟลเดอร์โปรเจกต์หลักที่: $TARGET_REPO"
    mkdir -p "$TARGET_REPO"
    cd "$TARGET_REPO"
    git init -b main
    echo "# Protein Local Vault" > README.md
    git add README.md
    git commit -m "chore: initial protein core local vault"
else
    cd "$TARGET_REPO"
fi

# 2. จำลองกระบวนการวิเคราะห์และจัดระเบียบข้อมูลเก่า (ใช้ตรรกะจาก sanitize.sh)
echo "🔍 กำลังสแกนและจัดระเบียบสคริปต์/รายงานในเครื่อง..."
mkdir -p reports sanitized_reports

# สร้างรายงานสรุปสถานะระบบจำลองภายในเครื่อง (แทนที่ตรรกะ cloud status เดิม)
SYS_REPORT="reports/local_system_report_$(date +%Y%m%d_%H%M%S).json"
cat << EOF > "$SYS_REPORT"
{
  "device_env": "Termux Proot-Distro Local",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "disk_usage": "$(df -h /data | awk 'NR==2 {print $5}')",
  "active_containers": "$(proot-distro list 2>/dev/null | grep installed || echo 'none')",
  "active_scripts_count": "$(find ~/nut-forensic -type f 2>/dev/null | wc -l)"
}
EOF

# กรองและจัดระเบียบข้อมูลรายงานด้วย jq (จำลองการทำงานของ sanitize.sh)
SANITIZED_FILE="sanitized_reports/sanitized_$(basename "$SYS_REPORT")"
jq '{
  environment: .device_env,
  time: .timestamp,
  storage: .disk_usage,
  containers: .active_containers,
  scripts_tracked: .active_scripts_count
}' "$SYS_REPORT" > "$SANITIZED_FILE"

echo "✅ จัดระเบียบข้อมูลเรียบร้อย: $SANITIZED_FILE"

# 3. ผูกข้อมูลและผลลัพธ์ทั้งหมดเข้ากับระบบ Git อัตโนมัติ (Git Workflow)
echo "🚀 กำลังซิงค์ข้อมูลเข้าสู่ระบบ Git..."

# ตรวจสอบการเปลี่ยนแปลง
git add .

# หากมีการเปลี่ยนแปลง ให้ทำการ Commit อัตโนมัติโดยใช้ Timestamp ควบคุมเวอร์ชัน
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    COMMIT_MSG="auto(core): sync local system report & pipeline update $(date +%Y-%m-%d_%H:%M)"
    git commit -m "$COMMIT_MSG"
    echo "✨ ทำการบันทึก (Commit) เวอร์ชันใหม่เรียบร้อยแล้ว!"
else
    echo "💡 ไม่พบการเปลี่ยนแปลงใหม่ สถานะ Git เป็นปัจจุบันแล้ว"
fi

echo "=========================================="
echo "🎯 ระบบทำงานร่วมกับ Git เสร็จสมบูรณ์!"
echo "=========================================="
