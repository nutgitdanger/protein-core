#!/data/data/com.termux/files/usr/bin/bash
set -u

export TARGET_DIR="$HOME/.config/dynu-audit"
export EC2_IP="43.208.48.65"
export EC2_USER="ubuntu"

# ค้นหาไฟล์ .pem จริงใน ~/.ssh อัตโนมัติกรณีระบุ path พลาด
FOUND_KEY=""
if [ -n "${KEY:-}" ] && [ -f "$KEY" ]; then
    FOUND_KEY="$KEY"
else
    FOUND_KEY=$(find "$HOME/.ssh" -maxdepth 1 -name "*.pem" 2>/dev/null | head -n 1)
fi
export KEY="${FOUND_KEY:-$HOME/.ssh/aws-controller-key.pem}"

echo "=== [1] REALITY ENV STATUS ==="
echo "KEY path : $KEY (Exists: $([ -f "$KEY" ] && echo YES || echo NO))"
echo "Target   : $EC2_USER@$EC2_IP"

echo -e "\n=== [2] ENSURE WG CONFIG ==="
mkdir -p "$TARGET_DIR"
if [ ! -f "$TARGET_DIR/wg0.conf" ]; then
    cat << 'WGEOF' > "$TARGET_DIR/wg0.conf"
[Interface]
PrivateKey = 0GuTfunEtB3Cu9EdXLcmLN0e1ohLJd8B/u50AVbTs3c=
Address = 10.66.0.2/32
MTU = 1400

[Peer]
PublicKey = CQNiXk4BNxcNDEEvgjFmJ+utI5rJhSilB8w8SIIFbwU=
Endpoint = nutgit.casacam.net:51888
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
WGEOF
    echo "Created wg0.conf"
else
    echo "wg0.conf already exists"
fi

echo -e "\n=== [3] CONFIG CONTENT ==="
cat "$TARGET_DIR/wg0.conf"

echo -e "\n=== [4] LIVE SSH REALITY PROBE ==="
if [ -f "$KEY" ]; then
    ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 "$EC2_USER@$EC2_IP" 'echo "REMOTE_OK: $(hostname) uptime: $(uptime -p)"' 2>/dev/null || echo "REMOTE: Unreachable / Timeout (Check AWS Security Group Port 22 or CGNAT/VPN state)"
else
    echo "REMOTE: Skip SSH probe (Key file not found on disk)"
fi
