import argparse
import json
import hashlib
import sys

PROMOTION_MAX = 5


def fail(code, message):
    return {
        "accepted": False,
        "code": code,
        "message": message
    }


def ok(message, **extra):
    result = {
        "accepted": True,
        "code": "ACCEPT",
        "message": message
    }
    result.update(extra)
    return result


def stable_hash(value):
    raw = json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False
    ).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def index_nodes(nodes):
    return {node["id"]: node for node in nodes}


def trace_to_root(nodes, node_id):
    seen = set()
    current = node_id

    while current != "ROOT":
        if current in seen:
            return False, "LINEAGE_CYCLE"

        seen.add(current)

        node = nodes.get(current)
        if node is None:
            return False, "MISSING_PARENT"

        parent = node.get("parent_id")
        if not parent:
            return False, "NO_ROOT_PATH"

        current = parent

    return True, "ROOT_REACHABLE"


def validate_relationships(nodes, edges):
    for edge in edges:
        source = edge.get("from")
        target = edge.get("to")

        if source not in nodes:
            return False, f"MISSING_SOURCE:{source}"

        if target not in nodes:
            return False, f"MISSING_TARGET:{target}"

    return True, "RELATIONSHIPS_VALID"


def required_meaning_preserved(old, new):
    required = set(old.get("required_meaning", []))
    candidate = set(new.get("meaning", []))

    missing = sorted(required - candidate)

    if missing:
        return False, missing

    return True, []


def validated_knowledge_preserved(old, new):
    old_knowledge = set(old.get("validated_knowledge", []))
    new_knowledge = set(new.get("validated_knowledge", []))

    missing = sorted(old_knowledge - new_knowledge)

    if missing:
        return False, missing

    return True, []


def cycle_state(candidate):
    value = candidate.get("cycle", 0)

    if not isinstance(value, int):
        return None

    if value < 0 or value > PROMOTION_MAX:
        return None

    return value


def promotion(candidate):
    current = cycle_state(candidate)

    if current != PROMOTION_MAX:
        return {
            "promote": False,
            "cycle": current
        }

    return {
        "promote": True,
        "cycle": 0,
        "promotion_id": stable_hash({
            "root_id": candidate.get("root_id"),
            "meaning": candidate.get("meaning", []),
            "evidence": candidate.get("evidence", [])
        })
    }


def compare(old, new):
    old_capability = float(old.get("capability", 0))
    new_capability = float(new.get("capability", 0))

    old_weight = float(old.get("weight", 0))
    new_weight = float(new.get("weight", 0))

    old_steps = int(old.get("steps", 0))
    new_steps = int(new.get("steps", 0))

    return {
        "capability_delta": new_capability - old_capability,
        "weight_delta": new_weight - old_weight,
        "step_delta": new_steps - old_steps,
        "improved_capability": new_capability > old_capability,
        "lighter": new_weight < old_weight,
        "shorter": new_steps < old_steps,
        "same_capability": new_capability == old_capability
    }


def evaluate(old, new):
    old_nodes = index_nodes(old.get("nodes", []))
    new_nodes = index_nodes(new.get("nodes", []))

    if "ROOT" not in old_nodes:
        return fail("ROOT_MISSING_OLD", "old structure has no ROOT")

    if "ROOT" not in new_nodes:
        return fail("ROOT_MISSING_NEW", "candidate has no ROOT")

    if old_nodes["ROOT"] != new_nodes["ROOT"]:
        return fail("ROOT_CHANGED", "validated ROOT was modified")

    relationship_ok, reason = validate_relationships(
        new_nodes,
        new.get("edges", [])
    )

    if not relationship_ok:
        return fail("RELATIONSHIP_INVALID", reason)

    for node_id in new_nodes:
        trace_ok, reason = trace_to_root(new_nodes, node_id)

        if not trace_ok:
            return fail(
                "ROOT_TRACE_FAILED",
                f"{node_id}:{reason}"
            )

    meaning_ok, missing = required_meaning_preserved(old, new)

    if not meaning_ok:
        return fail(
            "REQUIRED_MEANING_LOST",
            ",".join(missing)
        )

    knowledge_ok, missing = validated_knowledge_preserved(old, new)

    if not knowledge_ok:
        return fail(
            "VALIDATED_KNOWLEDGE_LOST",
            ",".join(missing)
        )

    cycle = cycle_state(new)

    if cycle is None:
        return fail("INVALID_CYCLE", "cycle must be 0..5")

    comparison = compare(old, new)

    if (
        comparison["same_capability"]
        and not comparison["lighter"]
        and not comparison["shorter"]
    ):
        return ok(
            "KEEP_EXISTING",
            decision="KEEP_EXISTING",
            comparison=comparison,
            cycle=cycle
        )

    candidate_id = stable_hash({
        "root_id": new.get("root_id"),
        "parent": old.get("id"),
        "candidate": new
    })

    promo = promotion(new)

    return ok(
        "CANDIDATE_ACCEPTED",
        decision="CREATE_CANDIDATE",
        candidate_id=candidate_id,
        comparison=comparison,
        cycle=cycle,
        promotion=promo
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("old")
    parser.add_argument("new")
    args = parser.parse_args()

    with open(args.old, "r", encoding="utf-8") as f:
        old = json.load(f)

    with open(args.new, "r", encoding="utf-8") as f:
        new = json.load(f)

    result = evaluate(old, new)

    print(json.dumps(
        result,
        indent=2,
        ensure_ascii=False,
        sort_keys=True
    ))

    sys.exit(0 if result["accepted"] else 1)


if __name__ == "__main__":
    main()
