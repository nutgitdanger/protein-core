#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail
WORKSPACE="$HOME/protein-core"
QUARANTINE_DIR="$WORKSPACE/12-runtime/conveyor/processing/quarantine_$(date +%Y%m%d_%H%M%S)"
n=0
while IFS= read -r file; do
  mkdir -p "$QUARANTINE_DIR"
  mv -n "$file" "$QUARANTINE_DIR/"
  n=$((n+1))
done < <(find "$WORKSPACE" \( -path "$WORKSPACE/.git" -o -path "*/quarantine_*" \) -prune -o -type f \( -name "*.tmp" -o -name "*.bak" -o -name "*~" \) -print)
echo "hygiene: moved $n file(s)"
[ "$n" -gt 0 ] && echo "  -> $QUARANTINE_DIR"
exit 0
