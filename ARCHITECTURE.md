# Protein Core: สถานะจริง (อัปเดต 2026-10-22)

## หลักการ
ทุกส่วนต้องมี ตัววัด -> เงื่อนไข -> การกระทำจริง ถ้าไม่มีการกระทำจริง ไม่เก็บไว้

## ส่วนที่ทำงานจริง
- protein-guardian.sh : daemon เดียว รันผ่าน runit (sv status protein-guardian)
  - วัด RAM จาก /proc/meminfo, แบต/อุณหภูมิจาก termux-battery-status (ต้องมีแอป Termux:API)
  - เกณฑ์: เข้า PAUSE เมื่อ RAM<600MB หรือ temp>=42C หรือ bat<=20% (ไม่เสียบสาย)
    กลับ OK เมื่อ RAM>900MB และ temp<=38C และ bat>=30% (หรือเสียบสาย)
  - PAUSE = ส่ง SIGSTOP ให้ worker ที่ลงทะเบียน, OK = SIGCONT
  - ความถี่ตรวจปรับตามภาระ 3-60 วินาที
  - สถานะ: ~/.cache/protein/status, เหตุการณ์: ~/.cache/protein/events.log
- Worker ลงทะเบียนโดย: echo $$ > ~/.cache/protein/workers/NAME.pid
  และลบตอนจบ: trap 'rm -f ~/.cache/protein/workers/NAME.pid' EXIT
  ห้ามลงทะเบียนงานที่ต้องรันตลอด (เช่น dynu-daemon เป็น DDNS)
- protein-hygiene.sh : ย้าย .tmp/.bak/~ เข้า quarantine (เรียกผ่าน pheal)

## Alias (ใน ~/.zshrc)
pguard = สถานะ service + ค่าปัจจุบัน | pstatus = ค่าปัจจุบัน | pevents = เหตุการณ์ล่าสุด

## ของเก่า ไม่ใช่ตัวควบคุม (heuristic เท่านั้น ไม่ได้เทรนหรือเรียนรู้จริง)
- neural-core-v2..v9, rbm-core.py, layers/L10-L12, synapse-mesh, protein-super-nexus.sh
  (pscan/ppulse/pheal) คำนวณสูตรถ่วงน้ำหนักแล้วพิมพ์ผล ไม่ได้สั่งอะไรกับระบบ
  ย้ายเข้า _archive/ แล้ว 2026-10-22 (pscan/ppulse อาจใช้ไม่ได้ ยกเว้น pheal)

## ข้อจำกัดของเครื่อง
OPPO F9, RAM 5.6GB, อ่าน /sys/class/power_supply ไม่ได้ (Permission denied)
ห้ามเรียก termux-battery-status ถี่กว่า 30 วินาที, ห้ามลด sleep ต่ำกว่า 2 วินาที

## EC2 (m7)
ปิดอยู่โดยตั้งใจ ยังไม่ส่งงานไป EC2 จนกว่าฝั่ง Termux นิ่ง
งานหนักต้องเช็ก: RAM พอ หรือ (EC2 running และ SSH ติด) ไม่ผ่านให้รอ

## ส่วนเสริม (2026-10-23)
- ~/pguard_sync.py : service ลูก (runit: pguard-sync) อ่านไฟล์ status ของ Guardian
  ส่งขึ้น DynamoDB pguard-metrics (profile ap7, ap-southeast-1) ทุก 300 วินาที มี ttl 30 วัน
  ไม่วัดค่าเอง ใช้ Guardian เป็นแหล่งข้อมูลเดียว ใช้ RAM ~50MB
- pall = protein-overview-live.sh ดูภาพรวมทุก service ในคำสั่งเดียว
