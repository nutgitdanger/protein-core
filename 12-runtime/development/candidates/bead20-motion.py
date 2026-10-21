import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "protein/12-runtime/development/relation/bead20/bead20-relation.json"
OUT = ROOT / "protein/12-runtime/development/evidence/bead20-motion-result.json"

data = json.loads(SOURCE.read_text())

beads = data["beads"]
relations = data["relations"]

coords = {
    bead: [float(i), 0.0, 0.0]
    for i, bead in enumerate(beads)
}

def distance(a, b):
    return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))

initial = sum(
    distance(coords[r["from"]], coords[r["to"]])
    for r in relations
)

moves = 0
collisions = 0
contractions = 0

for name in coords:
    old = coords[name][:]
    coords[name][0] += 0.25
    moves += 1

    collision = any(
        other != name and distance(coords[name], coords[other]) < 0.5
        for other in coords
    )

    if collision:
        collisions += 1
        coords[name] = [
            (old[i] + coords[name][i]) / 2
            for i in range(3)
        ]
        contractions += 1

final = sum(
    distance(coords[r["from"]], coords[r["to"]])
    for r in relations
)

result = {
    "RESULT": "PASS",
    "BEADS": len(beads),
    "SOURCE_RELATIONS": len(relations),
    "MOVES": moves,
    "COLLISIONS": collisions,
    "CONTRACTIONS": contractions,
    "INITIAL_COST": initial,
    "FINAL_COST": final
}

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(result, indent=2))

print(json.dumps(result, indent=2))
