#!/data/data/com.termux/files/usr/bin/bash
set -u
KEY="$HOME/.ssh/aws-controller-key.pem"
EC2="43.208.48.65"

echo "=== 1. LOCAL PHYSICAL/EGRESS ROUTE TO EC2 ==="
ip route get "$EC2"

echo -e "\n=== 2. ACTIVE LOCAL UP INTERFACES ==="
ip -o link show | grep 'UP'

echo -e "\n=== 3. LOCAL UDP/TCP SOCKETS (PORT 51888) ==="
ss -un | grep "51888" || ss -tn | grep "51888" || echo "No active socket matching port 51888 (Tunnel/Connection idle or inactive)"

echo -e "\n=== 4. REMOTE EC2 HARDWARE/WORKER PROCESS CHECK ==="
if [ -f "$KEY" ]; then
  ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 "ubuntu@$EC2" '
    echo "HOST: $(hostname)"
    echo "UPTIME: $(uptime -p)"
    echo "WORKER PROCESS:"
    ps -ef | grep queue-worker | grep -v grep || echo "queue-worker not running"
    echo -n "PID FILE STATUS: "
    if [ -s /home/ubuntu/dynu-offload/state/worker.pid ] && kill -0 "$(cat /home/ubuntu/dynu-offload/state/worker.pid)" 2>/dev/null; then
      echo "ALIVE (PID $(cat /home/ubuntu/dynu-offload/state/worker.pid))"
    else
      echo "DEAD/MISSING"
    fi
  '
else
  echo "SSH key missing at $KEY"
fi
