#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN INTERNAL PROCESS & THREAD AUDIT               "
echo "====================================================================="
echo "[📊 ACTIVE PROCESS SUMMARY (Sorted by CPU)]"
ps -e -o pid,ppid,%cpu,%mem,stat,comm --sort=-%cpu | head -n 12
echo "---------------------------------------------------------------------"
echo "[🔢 TOTAL ACTIVE PROCESSES]"
echo "Running/Sleeping processes: $(ps -e | wc -l)"
echo "====================================================================="
