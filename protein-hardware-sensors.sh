#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN HARDWARE & THERMAL / GUI AUDIT                 "
echo "====================================================================="
echo "[🌡️ THERMAL & TEMPERATURE STATUS]"
dumpsys thermalservice 2>/dev/null || cat /sys/class/thermal/thermal_zone*/type 2>/dev/null || echo "Thermal stats restricted by Android Sandbox."

echo "---------------------------------------------------------------------"
echo "[🖥️ DISPLAY & GUI / SURFACEFLINGER STATUS]"
dumpsys window displays 2>/dev/null | grep -E "mDisplayId|mBaseDisplayWidth|mCurrentDisplayRect" || echo "Display server info restricted."
echo "====================================================================="
