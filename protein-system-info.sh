#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN SYSTEM ROOT & HARDWARE INFRASTRUCTURE          "
echo "====================================================================="
echo "[🧠 CPU ARCHITECTURE & CORES]"
uname -m && lscpu | grep -E "Model name|CPU\(s\):|Architecture|CPU max MHz" || getconf _NPROCESSORS_ONLN
echo "---------------------------------------------------------------------"
echo "[💾 MEMORY & STORAGE (RAM/ROM)]"
free -h
echo ""
df -h /data /storage/emulated/0 2>/dev/null || df -h
echo "---------------------------------------------------------------------"
echo "[🔌 KERNEL & SYSTEM BASE]"
uname -a
uptime
echo "====================================================================="
