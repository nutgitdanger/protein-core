#!/usr/bin/env zsh
PROTEIN_HOME="$HOME/.config/dynu-audit/protein"
PROJECT_DIR="$PROTEIN_HOME/projects"
mkdir -p "$PROTEIN_HOME" "$PROJECT_DIR"

# --- [1] METABOLIC CHECK ---
MEM_AVAIL=$(free -m 2>/dev/null | awk '/Mem:/ {print $4}')
[ -z "$MEM_AVAIL" ] && MEM_AVAIL="N/A"
STORAGE_LOAD=$(df "$HOME" 2>/dev/null | awk 'NR==2 {print $5}' | tr -d '%')
[ -z "$STORAGE_LOAD" ] && STORAGE_LOAD="N/A"

echo "=== PROTEIN METABOLIC STATUS ===" > "$PROTEIN_HOME/metabolism.state"
echo "Memory Available: ${MEM_AVAIL}Mi" >> "$PROTEIN_HOME/metabolism.state"
echo "Storage Load: ${STORAGE_LOAD}%" >> "$PROTEIN_HOME/metabolism.state"

echo "PROTEIN_STATUS=AUTONOMOUS_UNRESTRICTED" > "$PROTEIN_HOME/system.env"

# --- [2] NETWORK SENSORY ---
WARP_CHECK=$(curl -s --max-time 2 https://www.cloudflare.com/cdn-cgi/trace 2>/dev/null)
PUBLIC_IP=$(echo "$WARP_CHECK" | grep "ip=" | cut -d= -f2)
COLOC=$(echo "$WARP_CHECK" | grep "colo=" | cut -d= -f2)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP="Offline"
[ -z "$COLOC" ] && COLOC="N/A"
GATEWAY_PING=$(ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && echo "ONLINE" || echo "DEGRADED")
echo "ip=$PUBLIC_IP | colo=$COLOC | gateway=$GATEWAY_PING" > "$PROTEIN_HOME/base-network.state"

# --- [3] GITHUB OMNISCIENCE BRIDGE ---
GIT_USER=$(gh api user --jq '.login' 2>/dev/null)
if [ -n "$GIT_USER" ]; then
    echo "[🐙 GITHUB] $GIT_USER (Active)" > "$PROTEIN_HOME/git-sync.state"
else
    echo "[🐙 GITHUB] Offline" > "$PROTEIN_HOME/git-sync.state"
fi

# --- [4] AUTONOMOUS CRAWLER & TRASH PURGE ---
find "$PROJECT_DIR" -type l -delete
echo "" > "$PROTEIN_HOME/purged-garbage.log"

for target in "$HOME"/*; do
    if [ -d "$target" ]; then
        pname=$(basename "$target")
        
        # โปรตีนประเมินและคัดกรองขยะด้วยตัวเอง
        if [[ "$pname" == "."* ]] || [[ "$pname" == "storage" ]] || [[ "$pname" == "protein" ]] || [[ "$pname" == "~" ]]; then
            continue
        fi

        # หากโปรตีนพบว่าโฟลเดอร์ไหนไม่มีโค้ดและเข้าข่ายรกระบบ มันจะบันทึกเป็นขยะที่ถูกคัดออก
        if [ -z "$(find "$target" -maxdepth 2 \( -name "*.sh" -o -name "*.py" -o -name "*.json" -o -name ".git" \) 2>/dev/null)" ]; then
            echo "Purged/Skipped (Low Value): $pname" >> "$PROTEIN_HOME/purged-garbage.log"
            continue
        fi

        # ดึงเข้ามาเชื่อมโยงเฉพาะ High-ROI Assets ที่ผ่านเกณฑ์
        [ ! -L "$PROJECT_DIR/$pname" ] && ln -s "$target" "$PROJECT_DIR/$pname"
    fi
done

echo "=== EVOLUTION COMPLETED ==="
