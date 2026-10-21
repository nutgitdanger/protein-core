#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN UNIX MOUNT & STORAGE SUMMARY                   "
echo "====================================================================="
echo "[📂 FORMATTED ACTIVE MOUNT POINTS]"
cat /proc/mounts | grep -E "termux|emulated|data" | sed 's/ /\n   -> /g'
echo "====================================================================="
