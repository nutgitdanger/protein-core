#!/data/data/com.termux/files/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$CONFIG_DIR/.env" ] && source "$CONFIG_DIR/.env"

API_KEY="${API_KEY:-gv4MHf24nro3eC8d8E7K77vH70c3670h}"
RECORD_ID="13248427"
DOMAIN_NAME="nutgit.casacam.net"
TARGET_IP="${1:-43.208.48.65}"

if [ -z "$API_KEY" ]; then
  echo "[-] Error: API_KEY is missing."
  exit 1
fi

RES=$(curl -s -w "\n%{http_code}" -X POST "https://api.dynu.com/v2/dns/$RECORD_ID" \
  -H "API-Key: $API_KEY" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"$DOMAIN_NAME\", \"ipv4Address\": \"$TARGET_IP\"}")

HTTP_CODE=$(echo "$RES" | tail -n1)
BODY=$(echo "$RES" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
  echo "[+] Synced $DOMAIN_NAME -> $TARGET_IP (HTTP 200)"
else
  echo "[-] Failed to sync (HTTP $HTTP_CODE): $BODY"
  exit 1
fi
