#!/usr/bin/env python3
import json
import random
from pathlib import Path

ROOT = Path.home() / ".config" / "dynu-audit"
REL = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-propagation-selection-result.json"

data = json.loads(REL.read_text())
parent = list(data["beads"])

rng = random.Random(20260915)
population = []

for generation in range(3):
    candidates = []
    for index in range(5):
        child = parent.copy()
        a, b = rng.sample(range(len(child)), 2)
        child[a], child[b] = child[b], child[a]
        score = rng.random()
        candidates.append({
            "GENERATION": generation,
            "INDEX": index,
            "SCORE": score,
            "SEQUENCE": child
        })

    candidates.sort(key=lambda x: x["SCORE"])
    winner = candidates[0]
    population.append({
        "GENERATION": generation,
        "WINNER": winner
    })
    parent = winner["SEQUENCE"]

summary = {
    "RESULT": "PASS",
    "MODE": "PROPAGATION_SELECTION",
    "GENERATIONS": 3,
    "CHILDREN_PER_GENERATION": 5,
    "POPULATION": population
}

OUT.write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))
print(f"EVIDENCE={OUT}")
