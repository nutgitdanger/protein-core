#!/usr/bin/env bash
set -euo pipefail

TARGET_DOMAIN="nutgit.casacam.net"
FALLBACK_IPV4="43.208.48.65"
FALLBACK_IPV6="2406:da14:8587:cd00:ea5f:87c8:c661:ba8e"

WG_CONF="$HOME/.config/dynu-audit/wg0.conf"
CANONICAL_ENV="$HOME/.config/dynu-audit/config/canonical.env"
SSH_CONFIG="$HOME/.config/dynu-audit/runtime/ec2-offload/ssh-config"
L6_PY="$HOME/.config/dynu-audit/dynu-offload/protein/l6.py"

echo "=== [AUTO ROUTER] Checking network targets for $TARGET_DOMAIN ==="

RESOLVED_IPV4=$(dig +short "$TARGET_DOMAIN" A | tail -n1)
if [ -z "$RESOLVED_IPV4" ]; then
    echo "[-] IPv4 DNS resolution failed. Using Fallback IP: $FALLBACK_IPV4"
    ACTIVE_IP="$FALLBACK_IPV4"
else
    echo "[+] Resolved IPv4: $RESOLVED_IPV4"
    ACTIVE_IP="$RESOLVED_IPV4"
fi

if [ -f "$WG_CONF" ]; then
    sed -i "s/Endpoint = .*/Endpoint = ${ACTIVE_IP}:51888/" "$WG_CONF"
fi

if [ -f "$CANONICAL_ENV" ]; then
    sed -i "s/CANONICAL_HOST=.*/CANONICAL_HOST=${ACTIVE_IP}/" "$CANONICAL_ENV"
    sed -i "s#CANONICAL_DECISION_URL=.*#CANONICAL_DECISION_URL=http://${ACTIVE_IP}/decision#" "$CANONICAL_ENV"
fi

if [ -f "$SSH_CONFIG" ]; then
    sed -i "s/HostName .*/HostName ${ACTIVE_IP}/" "$SSH_CONFIG"
fi

if [ -f "$L6_PY" ]; then
    sed -i "s|ENDPOINT = .*|ENDPOINT = \"http://${ACTIVE_IP}/decision\"|" "$L6_PY"
fi

echo "=== [SUCCESS] Active target locked to: $ACTIVE_IP ==="
