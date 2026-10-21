#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN DEEP HARDWARE & STORAGE AUDIT                  "
echo "====================================================================="
echo "[🧠 CPU & CORES DETAILS]"
echo "Total Cores: $(getconf _NPROCESSORS_ONLN)"
lscpu | grep -E "Model name|Architecture|CPU max MHz|CPU min MHz"
echo "---------------------------------------------------------------------"
echo "[💾 RAM DETAILS (MEMORY)]"
free -h
echo ""
echo "Top Memory Consumers:"
ps -eo pid,%mem,%cpu,comm --sort=-%mem | head -n 6
echo "---------------------------------------------------------------------"
echo "[📦 ROM / STORAGE DETAILS (ROM USAGE & CAPACITY)]"
df -h /data /storage/emulated/0 2>/dev/null || df -h
echo "====================================================================="
