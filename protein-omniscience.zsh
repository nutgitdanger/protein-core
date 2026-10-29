export PROTEIN_HOME="$HOME/.config/dynu-audit"

prun() {
    local interval="${1:-3600}"
    echo "[*] Initializing Protein Long-Run Guardian (Interval: ${interval}s)..."
    while true; do
        date "+[%Y-%m-%d %H:%M:%S] Running background health check & local commit..." >> "$PROTEIN_HOME/runs/guardian.log"
        git -C "$PROTEIN_HOME" add -A >> "$PROTEIN_HOME/runs/guardian.log" 2>&1
        git -C "$PROTEIN_HOME" commit -m "protein: auto-background snapshot $(date +%Y%m%d_%H%M%S)" --quiet 2>/dev/null
        sleep "$interval"
    done &
    echo $! > "$PROTEIN_HOME/runs/guardian.pid"
    echo "[✓] Guardian active in background (PID: $(cat "$PROTEIN_HOME/runs/guardian.pid"))"
}

pstop() {
    if [ -f "$PROTEIN_HOME/runs/guardian.pid" ]; then
        kill "$(cat "$PROTEIN_HOME/runs/guardian.pid")" 2>/dev/null
        rm -f "$PROTEIN_HOME/runs/guardian.pid"
        echo "[✓] Protein Guardian stopped."
    else
        echo "[!] No active Guardian found."
    fi
}

psearch() {
    [[ -z "$1" ]] && { echo "Usage: psearch <keyword>"; return 1; }
    grep -rnw "$PROTEIN_HOME" -e "$1" --exclude-dir={runs,reports,.git}
}
