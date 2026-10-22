#!/usr/bin/env zsh
printf '%s\n' '=== GUARDIAN ==='
if [ -f "$HOME/.config/dynu-audit/runs/guardian.pid" ]; then
    pid=$(cat "$HOME/.config/dynu-audit/runs/guardian.pid")
    echo "$pid"
    ps -p "$pid" -o pid,ppid,stat,%cpu,%mem,etime,args 2>/dev/null || echo "Process not running"
else
    echo "No guardian.pid found"
fi

printf '\n%s\n' '=== LOAD / MEMORY ==='
uptime
free -h

printf '\n%s\n' '=== GUARDIAN LOG ==='
tail -30 "$HOME/.config/dynu-audit/runs/guardian.log" 2>/dev/null || echo "No log found"

printf '\n%s\n' '=== END ==='
