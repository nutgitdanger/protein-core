#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN ECOSYSTEM: DEEP PROCESS & DAEMON AUDIT         "
echo "====================================================================="
echo "[🔍 ALL RUNNING PROCESSES (USER: u0_a372)]"
ps -u u0_a372 -o pid,ppid,%cpu,%mem,cmd
echo "---------------------------------------------------------------------"
echo "[🌐 OPEN NETWORK PORTS & CONNECTIONS]"
ss -anp 2>/dev/null || netstat -an 2>/dev/null || echo "Network socket inspection restricted."
echo "====================================================================="
