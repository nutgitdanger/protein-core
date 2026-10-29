#!/data/data/com.termux/files/usr/bin/bash

set -u

TARGET="$HOME"
echo "============================================================"
echo " DYNU / TERMUX SAFE STRUCTURE AUDIT"
echo "============================================================"

echo
echo "[1] ENVIRONMENT"
printf 'HOME      : %s\n' "$HOME"
printf 'PREFIX    : %s\n' "${PREFIX:-unknown}"
printf 'SHELL     : %s\n' "${SHELL:-unknown}"
printf 'USER      : %s\n' "${USER:-unknown}"

echo
echo "[2] IMPORTANT DIRECTORIES"
for d in \
    "$HOME/bin" \
    "$HOME/.config" \
    "$HOME/.config/dynu-audit" \
    "$HOME/.nut-workspace" \
    "$HOME/projects" \
    "$HOME/archives"
do
    if [ -d "$d" ]; then
        echo "OK   $d"
    else
        echo "MISS $d"
    fi
done

echo
echo "[3] DYNU FILES"
find "$HOME" -maxdepth 3 -type f \
    \( -iname '*dynu*' -o -iname '*dns*' \) \
    -print 2>/dev/null | sort

echo
echo "[4] ZSH CONFIG / REFERENCES"
if [ -f "$HOME/.zshrc" ]; then
    echo "FOUND ~/.zshrc"
    grep -nEi 'dynu|project-map|archives|\.config/dynu' \
        "$HOME/.zshrc" 2>/dev/null || echo "No matching references"
else
    echo "MISS ~/.zshrc"
fi

echo
echo "[5] SCRIPT REFERENCES"
grep -RniE \
    'dynu-project-map\.sh|dynu_update\.sh|\.config/dynu-audit' \
    "$HOME/bin" "$HOME/.config" "$HOME/projects" \
    2>/dev/null | head -100 || echo "No references found"

echo
echo "[6] PM2"
if command -v pm2 >/dev/null 2>&1; then
    pm2 list 2>/dev/null
else
    echo "PM2 not installed / not in PATH"
fi

echo
echo "[7] ACTIVE PROCESSES"
ps -A 2>/dev/null | grep -Ei 'dynu|adguard|node|python|pm2' \
    | grep -v grep || echo "No matching processes"

echo
echo "[8] ZSH BACKUPS"
find "$HOME" -maxdepth 1 -type f \
    -name '.zshrc.*' -print 2>/dev/null | sort

echo
echo "[9] ROOT-LEVEL LOGS"
find "$HOME" -maxdepth 1 -type f \
    -name '*.log' -print 2>/dev/null | sort

echo
echo "============================================================"
echo " AUDIT ONLY — NOTHING WAS MOVED OR DELETED"
echo "============================================================"
