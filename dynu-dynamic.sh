#!/usr/bin/env bash
set -euo pipefail

TARGET_DOMAIN="nutgit.casacam.net"
FALLBACK_IP="43.208.48.65"
WG_CONF="$HOME/.config/dynu-audit/wg0.conf"
CANONICAL_ENV="$HOME/.config/dynu-audit/config/canonical.env"

echo "=== [DYNAMIC ROUTER] Checking active route for $TARGET_DOMAIN ==="

RESOLVED_IP=$(dig +short "$TARGET_DOMAIN" | tail -n1)

if [ -z "$RESOLVED_IP" ]; then
    echo "[-] Warning: Cannot resolve $TARGET_DOMAIN. Falling back to direct IP: $FALLBACK_IP"
    ACTIVE_TARGET="$FALLBACK_IP"
else
    echo "[+] Resolved $TARGET_DOMAIN -> $RESOLVED_IP"
    ACTIVE_TARGET="$TARGET_DOMAIN"
fi

if [ -f "$WG_CONF" ]; then
    sed -i "s/Endpoint = .*/Endpoint = ${ACTIVE_TARGET}:51888/" "$WG_CONF"
    echo "[✓] Updated WireGuard config to use: ${ACTIVE_TARGET}"
fi

if [ -f "$CANONICAL_ENV" ]; then
    sed -i "s/CANONICAL_HOST=.*/CANONICAL_HOST=${ACTIVE_TARGET}/" "$CANONICAL_ENV"
    sed -i "s#CANONICAL_DECISION_URL=.*#CANONICAL_DECISION_URL=http://${ACTIVE_TARGET}/decision#" "$CANONICAL_ENV"
    echo "[✓] Updated Canonical environment to use: ${ACTIVE_TARGET}"
fi

echo "=== [READY] Dynamic routing applied successfully. Target: ${ACTIVE_TARGET} ==="

# 3. อัปเดตไฟล์อื่นๆ เพิ่มเติม (เช่น SSH config และสคริปต์ Python ใน offload)
SSH_CONFIG="$HOME/.config/dynu-audit/runtime/ec2-offload/ssh-config"
if [ -f "$SSH_CONFIG" ]; then
    sed -i "s/HostName .*/HostName ${ACTIVE_TARGET}/" "$SSH_CONFIG"
    echo "[✓] Updated SSH config HostName to: ${ACTIVE_TARGET}"
fi

L6_PY="$HOME/.config/dynu-audit/dynu-offload/protein/l6.py"
if [ -f "$L6_PY" ]; then
    sed -i "s|ENDPOINT = .*|ENDPOINT = \"http://${ACTIVE_TARGET}/decision\"|" "$L6_PY"
    echo "[✓] Updated l.6 Python endpoint to: http://${ACTIVE_TARGET}/decision"
fi
