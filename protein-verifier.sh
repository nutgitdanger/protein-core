#!/usr/bin/env zsh
set -euo pipefail

PROTEIN_HOME="$HOME/.config/dynu-audit/protein"

echo "============================================================="
echo " PROTEIN SYSTEM — STRUCTURE & INTEGRITY VERIFICATION"
echo "============================================================="

echo -n "[1] Core DNA Status: "
if [ -f "$PROTEIN_HOME/00-core/dna/system.env" ]; then
    echo "OK (Found system.env)"
else
    echo "MISSING"
fi

echo -n "[2] Collector Inventory: "
if [ -s "$PROTEIN_HOME/02-collector/inventory/scripts-manifest.txt" ]; then
    echo "OK ($(wc -l < "$PROTEIN_HOME/02-collector/inventory/scripts-manifest.txt") scripts indexed)"
else
    echo "EMPTY"
fi

echo "[3] Projects Symlink Verification:"
mkdir -p "$PROTEIN_HOME/projects"
for p in ai-router network dns recovery dynu vpn github; do
    target="$PROTEIN_HOME/projects/$p"
    if [ -L "$target" ]; then
        echo "  - $p -> $(readlink "$target")"
    else
        echo "  - $p [No active symlink]"
    fi
done

echo "============================================================="
echo " VERIFICATION COMPLETED"
echo "============================================================="
