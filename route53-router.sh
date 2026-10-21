#!/usr/bin/env bash
set -euo pipefail

HOSTED_ZONE_ID="Z027721629XQEX5TP9SO2"
RECORD_NAME="nutgit.casacam.net"

CURRENT_INSTANCE_ID="i-027266ee089ef1d22"

EC2_IPV4=$(aws ec2 describe-instances \
  --instance-ids "$CURRENT_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text 2>/dev/null || echo "")

if [ -z "$EC2_IPV4" ] || [ "$EC2_IPV4" = "None" ]; then
    EC2_IPV4="43.208.48.65"
fi

EC2_IPV6=$(aws ec2 describe-instances \
  --instance-ids "$CURRENT_INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].NetworkInterfaces[0].Ipv6Addresses[*].Ipv6Address' \
  --output text 2>/dev/null | head -n1 || echo "")

if [ -z "$EC2_IPV6" ] || [ "$EC2_IPV6" = "None" ]; then
    EC2_IPV6="2406:da14:8587:cd00:ea5f:87c8:c661:ba8e"
fi

WG_CONF="$HOME/.config/dynu-audit/wg0.conf"
CANONICAL_ENV="$HOME/.config/dynu-audit/config/canonical.env"
SSH_CONFIG="$HOME/.config/dynu-audit/runtime/ec2-offload/ssh-config"
L6_PY="$HOME/.config/dynu-audit/dynu-offload/protein/l6.py"

echo "=== [ROUTE 53 ROUTER] Updating DNS records for $RECORD_NAME ==="

CHANGE_BATCH=$(cat << JSON
{
  "Comment": "Automated dual-stack dynamic update from Termux router",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [{"Value": "$EC2_IPV4"}]
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "AAAA",
        "TTL": 60,
        "ResourceRecords": [{"Value": "$EC2_IPV6"}]
      }
    }
  ]
}
JSON
)

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "$CHANGE_BATCH" >/dev/null

echo "[+] Route 53 DNS records updated successfully (IPv4: $EC2_IPV4, IPv6: $EC2_IPV6)"

if [ -f "$WG_CONF" ]; then
    sed -i "s/Endpoint = .*/Endpoint = ${EC2_IPV4}:51888/" "$WG_CONF"
fi

if [ -f "$CANONICAL_ENV" ]; then
    sed -i "s/CANONICAL_HOST=.*/CANONICAL_HOST=${EC2_IPV4}/" "$CANONICAL_ENV"
    sed -i "s#CANONICAL_DECISION_URL=.*#CANONICAL_DECISION_URL=http://${EC2_IPV4}/decision#" "$CANONICAL_ENV"
fi

if [ -f "$SSH_CONFIG" ]; then
    sed -i "s/HostName .*/HostName ${EC2_IPV4}/" "$SSH_CONFIG"
fi

if [ -f "$L6_PY" ]; then
    sed -i "s|ENDPOINT = .*|ENDPOINT = \"http://${EC2_IPV4}/decision\"|" "$L6_PY"
fi

echo "=== [SUCCESS] Configuration synchronized to dynamic AWS targets ==="
