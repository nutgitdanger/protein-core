#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN ECOSYSTEM: HIGH LOAD JOB INSPECTOR             "
echo "====================================================================="
echo "[🔥 TOP CPU CONSUMING PROCESSES]"
ps -eo pid,ppid,%cpu,%mem,comm --sort=-%cpu | head -n 10
echo "---------------------------------------------------------------------"
echo "[🧟 ZOMBIE OR UNINTERRUPTIBLE PROCESSES (D/Z STATE)]"
ps -eo pid,stat,comm | grep -E "D|Z" || echo "No uninterruptible/zombie processes found."
echo "====================================================================="
