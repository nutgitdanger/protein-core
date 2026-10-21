#!/usr/bin/env zsh
echo "====================================================================="
echo "           🌐 PROTEIN REAL-TIME NETWORK & WARP DIAGNOSTIC             "
echo "====================================================================="
echo "[🛡️ WARP & GATEWAY STATUS]"
if ip link show tun0 &>/dev/null; then
    echo "Status: ONLINE (tun0 interface active)"
else
    echo "Status: OFFLINE (tun0 interface inactive)"
fi

echo "---------------------------------------------------------------------"
echo "[🌍 PUBLIC IP & GEO-LOCATION]"
curl -s --max-time 3 https://ipinfo.io/json | grep -E "ip|city|country|org" || echo "Connection Timeout / Offline"

echo "---------------------------------------------------------------------"
echo "[⚡ REAL-TIME LATENCY (PING CHECK)]"
for host in 1.1.1.1 8.8.8.8 google.com; do
    ping -c 1 -W 2 $host 2>/dev/null | grep -E "rtt|time=" || echo "Failed to reach $host"
done
echo "====================================================================="
