#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN ECOSYSTEM: ABSOLUTE SYSTEM BLUEPRINT           "
echo "====================================================================="
echo "[🖥️ OS & BUILD FINGERPRINT]"
getprop ro.build.display.id 2>/dev/null || echo "Display ID restricted"
getprop ro.product.model 2>/dev/null || echo "Model restricted"
getprop ro.product.brand 2>/dev/null || echo "Brand restricted"
getprop ro.product.device 2>/dev/null || echo "Device restricted"
getprop ro.build.version.release 2>/dev/null || echo "Android Version restricted"
getprop ro.build.version.sdk 2>/dev/null || echo "SDK Version restricted"

echo "---------------------------------------------------------------------"
echo "[⚙️ PROCESSOR & HARDWARE TOPOLOGY]"
uname -a
cat /proc/cpuinfo | grep -E "processor|model name|Hardware|Serial" | uniq

echo "---------------------------------------------------------------------"
echo "[💾 FILE SYSTEM & ROOT PARTITIONS]"
df -h /data /system /vendor /boot 2>/dev/null

echo "---------------------------------------------------------------------"
echo "[🔌 RUNNING ENVIRONMENT & SHELL IDENTITY]"
echo "Shell: $SHELL"
echo "User: $(whoami)"
echo "Home: $HOME"
echo "Pathways Linked: $(ls -l ~/.config/dynu-audit/protein/00-core/map | wc -l) modules active"
echo "====================================================================="
