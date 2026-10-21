#!/usr/bin/env python3
import json
import math
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-collision-contract-result.json"

data = json.loads(REL.read_text())
beads = list(data["beads"])

positions = {
    b: [float(i), 0.0, 0.0]
    for i, b in enumerate(beads)
}

a = beads[0]
b = beads[1]

positions[b] = positions[a].copy()

COLLISION_DISTANCE = 0.035
CONTRACTION = 0.01

def distance(x, y):
    return math.sqrt(sum((x[i] - y[i]) ** 2 for i in range(3)))

before = distance(positions[a], positions[b])
collision_before = before < COLLISION_DISTANCE

if collision_before:
    direction = [0.0, 1.0, 0.0]
    positions[b] = [
        positions[a][0] + direction[0] * CONTRACTION,
        positions[a][1] + direction[1] * CONTRACTION,
        positions[a][2] + direction[2] * CONTRACTION,
    ]

after = distance(positions[a], positions[b])
collision_after = after < COLLISION_DISTANCE

result = {
    "RESULT": "PASS",
    "MODE": "COLLISION_CONTRACT",
    "TEMPLATE": False,
    "BEADS": len(beads),
    "TEST_PAIR": [a, b],
    "COLLISION_BEFORE": collision_before,
    "DISTANCE_BEFORE": before,
    "CONTRACTION": CONTRACTION,
    "DISTANCE_AFTER": after,
    "COLLISION_AFTER": collision_after,
    "CONTRACTED": collision_before and after > before,
    "RESOLVED": collision_before and not collision_after,
}

if not result["COLLISION_BEFORE"]:
    result["RESULT"] = "FAIL"
elif not result["CONTRACTED"]:
    result["RESULT"] = "FAIL"
elif result["COLLISION_AFTER"]:
    result["RESULT"] = "FAIL"

OUT.write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
print(f"EVIDENCE={OUT}")
