import re, sys, time
from datetime import datetime, timezone, timedelta
from decimal import Decimal
import boto3
from botocore.config import Config

REGION = "ap-southeast-1"
PROFILE = "ap7"
TABLE = "pguard-metrics"
STATUS = "/data/data/com.termux/files/home/.cache/protein/status"
TTL_DAYS = 30

def read_status():
    with open(STATUS) as f:
        parts = f.read().strip().split()
    d = {"state": parts[0]}
    for kv in parts[1:]:
        k, _, v = kv.partition("=")
        d[k] = v
    return d

def main():
    try:
        s = read_status()
    except Exception as e:
        print("skip: no guardian status:", e, flush=True); return 1
    now = datetime.now(timezone.utc)
    item = {
        "timestamp": now.isoformat().replace("+00:00", "Z"),
        "state": s["state"],
        "plug": s.get("plug", "UNKNOWN"),
        "ttl": int((now + timedelta(days=TTL_DAYS)).timestamp()),
    }
    for src, dst in (("mem", "mem_avail_mb"), ("bat", "battery_pct"), ("t", "temp_c")):
        v = s.get(src)
        if v is not None and re.fullmatch(r"-?\d+", v) and int(v) >= 0:
            item[dst] = Decimal(v)
    cfg = Config(connect_timeout=5, read_timeout=5, retries={"max_attempts": 1})
    table = boto3.Session(profile_name=PROFILE, region_name=REGION).resource("dynamodb", config=cfg).Table(TABLE)
    try:
        table.put_item(Item=item)
        print(f"[{item['timestamp']}] sync ok -> {item['state']} mem={item.get('mem_avail_mb')} bat={item.get('battery_pct')} t={item.get('temp_c')}", flush=True)
        return 0
    except Exception as e:
        print("sync error:", e, flush=True); return 1

if __name__ == "__main__":
    if "--loop" in sys.argv:
        while True:
            main(); time.sleep(300)
    else:
        sys.exit(main())
