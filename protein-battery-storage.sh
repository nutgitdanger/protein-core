#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN UNIX MOUNT & STORAGE AUDIT                     "
echo "====================================================================="
echo "[🔋 BATTERY & POWER STATUS]"
if [ -f /sys/class/power_supply/battery/capacity ]; then
    echo "Battery Level: $(cat /sys/class/power_supply/battery/capacity)% [Status: $(cat /sys/class/power_supply/battery/status 2>/dev/null)]"
else
    dumpsys battery 2>/dev/null | grep -E "level|status" || echo "Battery direct check restricted."
fi

echo "---------------------------------------------------------------------"
echo "[🗂️ ACTIVE UNIX MOUNT POINTS (/proc/mounts)]"
cat /proc/mounts | grep -E "termux|emulated|data"
echo "====================================================================="
