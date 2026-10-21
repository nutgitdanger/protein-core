#!/usr/bin/env zsh
echo "====================================================================="
echo "           🧬 PROTEIN ECOSYSTEM: LOAD STABILIZER & PURGE             "
echo "====================================================================="
echo "[🧹 CLEANING STALE ZSH/PS PROCESS ARTIFACTS]"
pkill -9 -f "protein-.*-audit" 2>/dev/null
pkill -9 -f "protein-load" 2>/dev/null
echo "Stale background inspection threads purged."
echo "---------------------------------------------------------------------"
echo "[📊 SYSTEM LOAD CHECK (POST-PURGE)]"
uptime
echo "====================================================================="
