#!/bin/zsh

# ใช้โฟลเดอร์ lock ภายในโปรเจกต์ ป้องกันปัญหา Read-only file system
LOCK_DIR="$HOME/.config/dynu-audit/containers/protein/.lock"
mkdir -p "$LOCK_DIR"
LOCK_FILE="$LOCK_DIR/protein-worker.lock"

if [ -f "$LOCK_FILE" ]; then
    echo "⚠️ ปฏิเสธการรันทับซ้อน: ระบบกำลังทำงานอยู่แล้ว"
    exit 1
fi

echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

echo "🚀 เริ่มต้นรันงาน..."
sleep 3
echo "✅ งานเสร็จสิ้นเรียบร้อย!"
