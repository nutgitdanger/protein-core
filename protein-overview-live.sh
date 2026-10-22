#!/data/data/com.termux/files/usr/bin/bash
S=$HOME/.cache/protein
echo "===== PROTEIN OVERVIEW $(date '+%F %T') ====="
echo "-- services --"
for s in protein-guardian pguard-sync; do sv status "$s" 2>&1; done
echo "-- ค่าปัจจุบัน (Guardian) --"; cat "$S/status" 2>/dev/null || echo "(ไม่มี status)"
echo "-- เหตุการณ์ล่าสุด --"; tail -n 5 "$S/events.log" 2>/dev/null || echo "(ว่าง)"
echo "-- workers ที่คุมอยู่ --"; ls "$S/workers" 2>/dev/null | sed 's/\.pid$//' | grep . || echo "(ไม่มี)"
echo "-- process ของเรา (RSS KB) --"
ps -eo pid,rss,pcpu,etime,cmd | grep -E 'protein-guardian|pguard_sync' | grep -v grep
echo "-- git --"; git -C "$HOME/protein-core" log --oneline -1; git -C "$HOME/protein-core" status --short | head -5
echo "-- ระบบ --"; uptime
