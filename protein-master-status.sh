#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN ECOSYSTEM: MASTER STATUS DASHBOARD             "
echo "====================================================================="
echo "[📂 PINNED MAP INVENTORY]"
ls -l ~/.config/dynu-audit/protein/00-core/map
echo "---------------------------------------------------------------------"
echo "[⚙️ SYSTEM LOAD & UPTIME]"
uptime
echo "---------------------------------------------------------------------"
echo "[💾 RAM USAGE]"
free -h | grep -E "Mem|Swap"
echo "---------------------------------------------------------------------"
echo "[🌐 ACTIVE IP & INTERFACE]"
ip -4 addr show ccmni2 2>/dev/null | grep "inet" || echo "Cellular interface inactive"
echo "====================================================================="
