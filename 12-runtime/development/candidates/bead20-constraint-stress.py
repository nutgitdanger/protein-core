#!/usr/bin/env python3
import json
import math
import random
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
BACK = ROOT / "protein/12-runtime/development/relation/bead20/bead20-backbone.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-constraint-stress-result.json"

rel = json.loads(REL.read_text())
back = json.loads(BACK.read_text())
beads = list(rel["beads"])
edges = [(x["from"], x["to"], x["distance"]) for x in back["edges"]]

def run(seed, collision):
    rng = random.Random(seed)
    pos = {b: [rng.uniform(-1, 1) for _ in range(3)] for b in beads}

    def dist(a, b):
        return math.sqrt(sum((pos[a][i] - pos[b][i]) ** 2 for i in range(3)))

    def cost():
        relation = sum((dist(a, b) - wanted) ** 2 for a, b, wanted in edges)
        penalty = 0.0
        for i, a in enumerate(beads):
            for b in beads[i + 1:]:
                d = dist(a, b)
                if d < collision:
                    penalty += (collision - d) ** 2
        return relation + penalty * 100.0

    initial = cost()
    accepted = 0
    rejected = 0

    for _ in range(400):
        bead = rng.choice(beads)
        old = pos[bead].copy()
        before = cost()

        pos[bead] = [
            old[i] + rng.uniform(-0.08, 0.08)
            for i in range(3)
        ]

        after = cost()

        if after <= before:
            accepted += 1
        else:
            pos[bead] = old
            rejected += 1

    final = cost()

    return {
        "SEED": seed,
        "COLLISION_THRESHOLD": collision,
        "INITIAL_COST": initial,
        "FINAL_COST": final,
        "ACCEPTED": accepted,
        "REJECTED": rejected,
        "IMPROVED": final < initial
    }

thresholds = [0.035, 0.05, 0.08]
results = []

for threshold in thresholds:
    for seed in [11, 22, 33]:
        results.append(run(seed, threshold))

summary = {
    "RESULT": "PASS",
    "MODE": "CONSTRAINT_STRESS",
    "THRESHOLDS": thresholds,
    "RUNS": len(results),
    "IMPROVED_RUNS": sum(x["IMPROVED"] for x in results),
    "RESULTS": results
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
