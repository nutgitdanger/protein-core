#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN KERNEL & SYSTEM CORE AUDIT                     "
echo "====================================================================="
echo "[🔌 FULL KERNEL RELEASE & VERSION]"
uname -r
echo "---------------------------------------------------------------------"
echo "[📜 KERNEL BUILD & COMPILER DETAILS]"
uname -v
echo "---------------------------------------------------------------------"
echo "[💻 MACHINE & PROCESSOR ARCHITECTURE]"
uname -m
echo "---------------------------------------------------------------------"
echo "[📂 KERNEL COMMAND LINE (BOOT CONFIG)]"
cat /proc/cmdline 2>/dev/null || echo "Proc cmdline restricted by sandbox."
echo "---------------------------------------------------------------------"
echo "[📋 LOADED KERNEL MODULES]"
lsmod 2>/dev/null || cat /proc/modules 2>/dev/null | head -n 20 || echo "Kernel modules list restricted."
echo "====================================================================="
