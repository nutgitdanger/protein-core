#!/data/data/com.termux/files/usr/bin/bash
PIDFILE="$HOME/.config/dynu-audit/dynu.pid"
LOGFILE="$HOME/.config/dynu-audit/dynu.log"
SCRIPT="$HOME/.config/dynu-audit/dynu-sync.sh"
INTERVAL=900

case "$1" in
  start)
    if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
      echo "Dynu daemon is already running (PID: $(cat $PIDFILE))."
      exit 0
    fi
    echo "Starting Dynu sync daemon..."
    nohup bash -c '
      echo $$ > "$1"
      while true; do
        "$2" >> "$3" 2>&1
        sleep "$4"
      done
    ' _ "$PIDFILE" "$SCRIPT" "$LOGFILE" "$INTERVAL" &>/dev/null &
    sleep 1
    echo "Started with PID $(cat $PIDFILE)"
    ;;
  stop)
    if [ -f "$PIDFILE" ]; then
      KILLPID=$(cat "$PIDFILE")
      kill "$KILLPID" 2>/dev/null || true
      rm -f "$PIDFILE"
      pkill -f "$SCRIPT" 2>/dev/null || true
      echo "Stopped Dynu daemon (PID: $KILLPID)."
    else
      echo "No PID file found."
    fi
    ;;
  status)
    if [ -f "$PIDFILE" ] && kill -0 $(cat "$PIDFILE") 2>/dev/null; then
      echo "STATUS: RUNNING (PID: $(cat $PIDFILE))"
      echo "Last 3 log entries:"
      tail -n 3 "$LOGFILE" 2>/dev/null || echo "No logs yet."
    else
      echo "STATUS: STOPPED / DEAD"
      [ -f "$LOGFILE" ] && echo "Last log:" && tail -n 1 "$LOGFILE"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac
