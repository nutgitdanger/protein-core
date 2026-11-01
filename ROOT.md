# ROOT: จุดอ้างอิงเดียวของโครงการ

## แกนหลัก
- repo: ~/work/protein-core (remote: nutgitdanger/protein-core, branch main)
- ก่อนเริ่มทุกครั้ง: `git status` และ `git log origin/main..HEAD`

## กติกา
1. สคริปต์ที่ push ต้องตั้ง ALLOW_PUSH=1 เท่านั้น
2. จะสร้างส่วนประกอบใหม่ได้ต่อเมื่อค้นใน ROOT.md แล้วไม่มีของเดิม
3. ผลทดสอบต้องรันซ้ำได้ และบันทึกคำสั่งที่ใช้
4. ข้อความว่า "ผ่าน" ต้องมาจากการวัดจริง ไม่ใช่ข้อความที่เขียนตายตัว

## สถานะ (อัปเดตด้วยมือ)
- 2026-11-01: ล้าง Termux แล้ว, protein-core clean และตรงกับ origin/main
- ค้าง: ยังไม่ได้ทดสอบการชนทุกคู่บนข้อมูลจริง

## ส่วนประกอบ
| ชื่อ | ที่อยู่ | หน้าที่ | สถานะ |
|---|---|---|---|
| bead check | tools/bead_check.py | ตรวจการชนทุกคู่ ย้อนกลับถ้าการขยับทำให้แย่ลง | ใหม่ ยังไม่ทดสอบกับข้อมูลจริง |
| auto-pushers | protein-master-organism.sh, protein-paper-synapse.sh, protein-reconcile.sh | commit/push เอง | ปิดด้วย guard แล้ว |
