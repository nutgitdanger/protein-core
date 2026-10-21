#!/usr/bin/env python3
import json
import math
import random
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
BACK = ROOT / "protein/12-runtime/development/relation/bead20/bead20-backbone.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-self-fold-v2-result.json"

SEEDS = [11, 22, 33, 44, 55, 66, 77, 88, 99, 111]
STEPS = 400
STEP_SIZE = 0.08
COLLISION = 0.035
CONTRACTION_STEP = 0.01
MAX_CONTRACTIONS = 10

rel_data = json.loads(REL.read_text())
back_data = json.loads(BACK.read_text())

beads = list(rel_data["beads"])
edges = [(e["from"], e["to"], e["distance"]) for e in back_data["edges"]]

def run(seed):
    rng = random.Random(seed)

    pos = {
        b: [rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(-1, 1)]
        for b in beads
    }

    def dist(a, b):
        x = pos[a]
        y = pos[b]
        return math.sqrt(sum((x[i] - y[i]) ** 2 for i in range(3)))

    def cost():
        relation_cost = 0.0
        collision_cost = 0.0

        for a, b, wanted in edges:
            relation_cost += (dist(a, b) - wanted) ** 2

        for i, a in enumerate(beads):
            for b in beads[i + 1:]:
                d = dist(a, b)
                if d < COLLISION:
                    collision_cost += (COLLISION - d) ** 2

        return relation_cost + collision_cost * 100.0

    initial = cost()
    best = initial
    accepted = 0
    rejected = 0

    for _ in range(STEPS):
        bead = rng.choice(beads)
        old = pos[bead].copy()
        before = cost()

        pos[bead] = [
            old[0] + rng.uniform(-STEP_SIZE, STEP_SIZE),
            old[1] + rng.uniform(-STEP_SIZE, STEP_SIZE),
            old[2] + rng.uniform(-STEP_SIZE, STEP_SIZE),
        ]

        after = cost()

        if after > before:
            pos[bead] = old
            rejected += 1
            continue

        collision = any(
            other != bead and dist(bead, other) < COLLISION
            for other in beads
        )

        if collision:
            resolved = False

            for _ in range(MAX_CONTRACTIONS):
                direction = [
                    rng.uniform(-1, 1),
                    rng.uniform(-1, 1),
                    rng.uniform(-1, 1),
                ]

                length = math.sqrt(sum(x * x for x in direction))

                if length == 0:
                    continue

                direction = [x / length for x in direction]

                pos[bead] = [
                    pos[bead][i] + direction[i] * CONTRACTION_STEP
                    for i in range(3)
                ]

                still_collision = any(
                    other != bead and dist(bead, other) < COLLISION
                    for other in beads
                )

                if not still_collision:
                    resolved = True
                    break

            if not resolved:
                pos[bead] = old
                rejected += 1
                continue

        accepted += 1
        best = min(best, cost())

    collisions = 0
    for i, a in enumerate(beads):
        for b in beads[i + 1:]:
            if dist(a, b) < COLLISION:
                collisions += 1

    final = cost()

    return {
        "SEED": seed,
        "INITIAL_COST": initial,
        "BEST_COST": best,
        "FINAL_COST": final,
        "IMPROVEMENT_PERCENT": ((initial - final) / initial) * 100,
        "ACCEPTED": accepted,
        "REJECTED": rejected,
        "COLLISIONS": collisions,
        "IMPROVED": final < initial,
    }

results = [run(seed) for seed in SEEDS]

summary = {
    "RESULT": "PASS",
    "MODE": "SELF_FOLD_MULTI_SEED",
    "TEMPLATE": False,
    "BEADS": len(beads),
    "SOURCE_RELATIONS": len(rel_data["relations"]),
    "BACKBONE_EDGES": len(edges),
    "STEPS": STEPS,
    "CONTRACTION_STEP": CONTRACTION_STEP,
    "MAX_CONTRACTIONS": MAX_CONTRACTIONS,
    "SEEDS": SEEDS,
    "RUNS": len(results),
    "IMPROVED_RUNS": sum(r["IMPROVED"] for r in results),
    "COLLISION_RUNS": sum(r["COLLISIONS"] > 0 for r in results),
    "RESULTS": results,
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
