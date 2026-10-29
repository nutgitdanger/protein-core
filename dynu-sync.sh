#!/data/data/com.termux/files/usr/bin/bash
DYNU_PWD="YOUR_DYNU_DDNS_PASSWORD_OR_SHA256"
DOMAIN="protein-ec2.remotewire.net"
EC2_IP="43.208.48.65"

echo "[$DOMAIN] Syncing EC2 IP ($EC2_IP) to Dynu..."
RESPONSE=$(curl -s "https://api.dynu.com/nic/update?hostname=${DOMAIN}&myip=${EC2_IP}&password=${DYNU_PWD}")
echo "API Response: $RESPONSE"
