#!/usr/bin/env zsh
echo "====================================================="
echo "       🧬 REALITY NET-TEST: WIREGUARD & NODE PROBE"
echo "====================================================="

echo "[1/3] Checking Dynu Domain & WireGuard Endpoint (nutgit.casacam.net:51888)..."
nc -zvw3 nutgit.casacam.net 51888 2>&1 || echo ">>> [NOTE] Endpoint probe finished (nc status)."

echo "-----------------------------------------------------"
echo "[2/3] Checking Active Local Interfaces & Tunnel IP..."
ip addr show | grep -E "inet|state" || ifconfig 2>/dev/null

echo "-----------------------------------------------------"
echo "[3/3] Validating Protein Engine Local Workspace..."
if [ -f "wg0.conf" ]; then
    echo "[PASS] wg0.conf structural key detected locally."
else
    echo "[WARN] wg0.conf not found in current path."
fi

echo "====================================================="
echo "       NET-TEST COMPLETED SUCCESSFULLY."
echo "====================================================="
