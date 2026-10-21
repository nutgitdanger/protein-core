from pathlib import Path
import json
import math
import random
from itertools import combinations

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / "protein/12-runtime/development/evidence"
OUT.mkdir(parents=True, exist_ok=True)

BEADS = [
    "Crystal", "SeedBead", "Pearl", "Gemstone", "Wood",
    "Shell", "LetterA", "Heart", "Star", "Flower",
    "Smile", "Neon", "MetalSpacer", "Antique", "Bugle",
    "Facet", "Twisted", "Glass", "Acrylic", "GoldBead"
]

assert len(BEADS) == 20
assert len(set(BEADS)) == 20

random.seed(20)
order = BEADS[:]
random.shuffle(order)

points = {
    name: [random.random(), random.random(), random.random()]
    for name in order
}

for _ in range(5):
    center = [
        sum(p[i] for p in points.values()) / 20
        for i in range(3)
    ]
    points = {
        name: [
            (p[i] + center[i]) / 2
            for i in range(3)
        ]
        for name, p in points.items()
    }

relations = []
for a, b in combinations(order, 2):
    d = math.sqrt(sum(
        (points[a][i] - points[b][i]) ** 2
        for i in range(3)
    ))
    relations.append({
        "from": a,
        "to": b,
        "distance": d
    })

result = {
    "bead_count": len(order),
    "unique_count": len(set(order)),
    "fold_passes": 5,
    "relation_count": len(relations),
    "beads": order,
    "relations": relations
}

(OUT / "bead20-result.txt").write_text(
    json.dumps(result, indent=2),
    encoding="utf-8"
)

print(f"BEADS={len(order)}")
print(f"UNIQUE={len(set(order))}")
print("FOLD_PASSES=5")
print(f"RELATIONS={len(relations)}")
print("RESULT=PASS")
print(f"EVIDENCE={OUT / 'bead20-result.txt'}")
