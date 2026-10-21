#!/data/data/com.termux/files/usr/bin/bash
EC2_IP="43.208.48.65"
ROUTER_IP="192.168.1.254"

echo "=== 1. Local Gateway / Router Check ($ROUTER_IP) ==="
ping -c 3 -W 2 "$ROUTER_IP" 2>&1 | tail -n 2

echo "=== 2. Internet / ISP Outbound Check (1.1.1.1) ==="
ping -c 3 -W 2 1.1.1.1 2>&1 | tail -n 2

echo "=== 3. EC2 ICMP Check ($EC2_IP) ==="
ping -c 3 -W 2 "$EC2_IP" 2>&1 | tail -n 2

echo "=== 4. EC2 TCP/80 (HTTP Control Plane / Web) Check ==="
nc -z -w 3 "$EC2_IP" 80 && echo "TCP/80 OPEN" || echo "TCP/80 CLOSED/BLOCKED"

echo "=== 5. EC2 TCP/22 (SSH) Check ==="
nc -z -w 3 "$EC2_IP" 22 && echo "TCP/22 OPEN" || echo "TCP/22 CLOSED/BLOCKED (expected if SG restricts)"

echo "=== 6. Tracepath / Path to EC2 ==="
which tracepath >/dev/null 2>&1 && tracepath -n "$EC2_IP" 2>&1 | head -n 10 || echo "tracepath not installed (pkg install iputils)"
