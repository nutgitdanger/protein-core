#!/usr/bin/env python3
"""ตรวจการชนของอนุภาคทุกคู่ และขยับทีละขั้น ย้อนกลับถ้าทำให้การชนเพิ่ม"""
import math


def collisions(pos, r):
    keys = list(pos)
    hits = []
    for i in range(len(keys)):
        for j in range(i + 1, len(keys)):
            a, b = keys[i], keys[j]
            if math.dist(pos[a], pos[b]) < r:
                hits.append((a, b))
    return hits


def resolve(pos, r, step=0.01, max_steps=50):
    before = collisions(pos, r)
    moves = 0
    for _ in range(max_steps):
        hits = collisions(pos, r)
        if not hits:
            break
        a, b = hits[0]
        old = list(pos[b])
        pos[b] = [old[0], old[1] + step, old[2]]
        if len(collisions(pos, r)) > len(hits):
            pos[b] = old
            break
        moves += 1
    return {"before": before, "moves": moves, "after": collisions(pos, r)}


def self_test():
    pos = {"a": [0.0, 0.0, 0.0], "b": [0.01, 0.0, 0.0], "c": [1.0, 1.0, 1.0]}
    rep = resolve(pos, 0.035)
    assert rep["before"], "ควรพบการชนก่อนแก้"
    assert len(rep["after"]) <= len(rep["before"]), "การชนต้องไม่เพิ่ม"
    print("PASS", rep)


if __name__ == "__main__":
    self_test()
