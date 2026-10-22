#!/data/data/com.termux/files/usr/bin/bash
S=$HOME/.cache/protein
mkdir -p "$S/workers"
state=OK; bat=-1; plug=UNPLUGGED; t=0; tick=0

read_battery() {
  local j
  j=$(timeout 5 termux-battery-status 2>/dev/null) || return
  bat=$(jq -r '.percentage // -1' <<<"$j")
  plug=$(jq -r '.plugged // "UNPLUGGED"' <<<"$j")
  t=$(jq -r '.temperature // 0 | floor' <<<"$j")
}

signal_workers() {
  local f
  for f in "$S"/workers/*.pid; do
    [[ -f $f ]] && kill -"$1" "$(<"$f")" 2>/dev/null
  done
}

trap 'signal_workers CONT; rm -f "$S/status"' EXIT
trap 'exit 0' INT TERM

# กู้ worker ที่อาจค้างจากรอบก่อน (เช่นถูก kill -9)
signal_workers CONT

while :; do
  mem=9999
  while read -r k v _; do
    [[ $k == MemAvailable: ]] && { mem=$((v/1024)); break; }
  done </proc/meminfo

  (( tick % 6 == 0 )) && read_battery
  tick=$((tick+1))

  charging=0; [[ $plug != UNPLUGGED ]] && charging=1
  new=$state
  if [[ $state == OK ]]; then
    (( mem < 600 )) && new=PAUSE
    (( t >= 42 )) && new=PAUSE
    (( bat >= 0 && bat <= 20 && charging == 0 )) && new=PAUSE
  else
    if (( mem > 900 && t <= 38 )) && { (( bat < 0 || bat >= 30 )) || (( charging )); }; then
      new=OK
    fi
  fi

  if [[ $new != "$state" ]]; then
    [[ $new == PAUSE ]] && signal_workers STOP || signal_workers CONT
    state=$new
    echo "$(date +%T) $state mem=$mem bat=$bat t=$t plug=$plug" >> "$S/events.log"
    if [[ $(stat -c %s "$S/events.log") -gt 100000 ]]; then
      tail -n 200 "$S/events.log" > "$S/e.tmp" && mv "$S/e.tmp" "$S/events.log"
    fi
  fi

  echo "$state mem=$mem bat=$bat t=$t plug=$plug" > "$S/status"
  if [[ $state == PAUSE ]] || (( mem < 900 )); then sleep 3 & else sleep 10 & fi
  wait $!
done
