#!/usr/bin/env zsh
clear
echo "====================================================================="
echo "        🧬 PROTEIN ECOSYSTEM: REAL-TIME SYSTEM PULSE [LIVE]          "
echo "====================================================================="
echo "[⚡ LIVE METRICS - $(date +'%T')] Target: OPPO CPH1823 (MT6771V/C)"
echo "---------------------------------------------------------------------"
echo "CPU Load Average : $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory Available : $(free -h | awk '/Mem:/ {print $7}') / $(free -h | awk '/Mem:/ {print $2}')"
echo "Active Processes : $(ps -e | wc -l)"
echo "Network Tunnel   : $(ip -4 addr show ccmni2 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || echo 'Offline')"
echo "====================================================================="
