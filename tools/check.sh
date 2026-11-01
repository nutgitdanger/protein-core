#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
fail=0

python3 -m py_compile tools/bead_check.py || fail=1
python3 tools/bead_check.py || fail=1

# ตรวจเฉพาะสคริปต์ที่เขียนด้วย bash เท่านั้น
for f in protein-master-organism.sh protein-paper-synapse.sh protein-reconcile.sh; do
  bash -n "$f" || fail=1
done

if [ "$fail" = 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECK FAILED"; fi
exit "$fail"
