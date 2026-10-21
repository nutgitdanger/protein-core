#!/usr/bin/env python3
import json
import math
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-collision-contract-v2-result.json"

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
CONTRACTION_STEP = 0.01
MAX_CONTRACTIONS = 10

def distance(x, y):
    return math.sqrt(sum((x[i] - y[i]) ** 2 for i in range(3)))

before = distance(positions[a], positions[b])
collision_before = before < COLLISION_DISTANCE

contractions = 0

while collision_before and distance(positions[a], positions[b]) < COLLISION_DISTANCE:
    contractions += 1

    positions[b] = [
        positions[a][0],
        positions[a][1] + contractions * CONTRACTION_STEP,
        positions[a][2],
    ]

    if contractions >= MAX_CONTRACTIONS:
        break

after = distance(positions[a], positions[b])
collision_after = after < COLLISION_DISTANCE

result = {
    "RESULT": "PASS",
    "MODE": "COLLISION_CONTRACT_V2",
    "TEMPLATE": False,
    "BEADS": len(beads),
    "TEST_PAIR": [a, b],
    "COLLISION_BEFORE": collision_before,
    "DISTANCE_BEFORE": before,
    "CONTRACTIONS": contractions,
    "CONTRACTION_STEP": CONTRACTION_STEP,
    "MAX_CONTRACTIONS": MAX_CONTRACTIONS,
    "DISTANCE_AFTER": after,
    "COLLISION_AFTER": collision_after,
    "RESOLVED": collision_before and not collision_after,
}

if not result["RESOLVED"]:
    result["RESULT"] = "FAIL"

OUT.write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
print(f"EVIDENCE={OUT}")
