#!/data/data/com.termux/files/usr/bin/bash
S=$HOME/.cache/protein
mkdir -p "$S/workers"
state=OK; bat=-1; plug=UNPLUGGED; t=0
prev_mem=-1; calm=0; last_bat=0

read_battery() {
  local j
  j=$(timeout 5 termux-battery-status 2>/dev/null) || return
  bat=$(jq -r '.percentage // -1' <<<"$j")
  plug=$(jq -r '.plugged // "UNPLUGGED"' <<<"$j")
  t=$(jq -r '.temperature // 0 | floor' <<<"$j")
}

signal_workers() {
  local f pid
  for f in "$S"/workers/*.pid; do
    [[ -f $f ]] || continue
    pid=$(<"$f")
    if [[ -z $pid ]] || ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$f"; continue
    fi
    kill -"$1" "$pid" 2>/dev/null
  done
}

trap 'signal_workers CONT; rm -f "$S/status"' EXIT
trap 'exit 0' INT TERM

signal_workers CONT

while :; do
  mem=9999
  while read -r k v _; do
    [[ $k == MemAvailable: ]] && { mem=$((v/1024)); break; }
  done </proc/meminfo

  now=$(printf '%(%s)T' -1)
  bat_iv=120
  (( bat >= 0 && bat < 35 )) && [[ $plug == UNPLUGGED ]] && bat_iv=30
  if (( now - last_bat >= bat_iv )); then read_battery; last_bat=$now; fi

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

  # ความถี่ตรวจปรับตามภาระ
  head=$(( mem - 600 ))
  delta=0; (( prev_mem >= 0 )) && delta=$(( prev_mem - mem ))
  prev_mem=$mem
  if   (( delta > 150 || head < 150 )); then iv=3;  calm=0
  elif [[ $state == PAUSE ]];           then iv=5;  calm=0
  elif (( head < 500 ));                then iv=5;  calm=0
  else
    calm=$((calm+1))
    iv=$(( 10 + calm * 5 )); (( iv > 60 )) && iv=60
  fi
  sleep "$iv" & wait $!
done
