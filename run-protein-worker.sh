#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

WROOT="$HOME/.config/dynu-audit/containers/protein"

echo "🧬 === PROTEIN RESEARCH WORKER ==="
echo "📂 Root: $WROOT"
echo "===================================="

proot-distro login debian --isolated \
  --bind "$WROOT:/worker" \
  -- /bin/bash -lc "
    set -e
    echo '✅ Preparing environment...'
    
    # สร้าง /etc/protein-research.env เพื่อให้สคริปต์เดิมใช้งานได้
    mkdir -p /etc
    cp /worker/config/research.env /etc/protein-research.env
    
    # โหลดค่า
    source /worker/config/research.env
    echo \"   PROTEIN_SOURCE=\$PROTEIN_SOURCE\"
    echo \"   OUTPUT_ROOT=\$OUTPUT_ROOT\"
    echo \"   RESEARCH_ROOT=\$RESEARCH_ROOT\"
    
    echo -e '\n🚀 Running research.zsh...'
    /bin/zsh /worker/bin/research.zsh
    RC=\$?
    echo -e \"\n✅ Done — Exit code: \$RC\"
    exit \$RC
  "
