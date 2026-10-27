#!/data/data/com.termux/files/usr/bin/python3
import math, json, sys
from pathlib import Path

MEMORY_FILE = Path.home() / "protein-core/pipeline/.neural_memory_history.json"

def sigmoid(x): return 1.0 / (1.0 + math.exp(-x))

def load_memory():
    if MEMORY_FILE.exists():
        try: return json.loads(MEMORY_FILE.read_text())
        except: pass
    return {"total_runs": 0, "avg_stress": 50.0, "adaptive_bias": 0.0}

def save_memory(m):
    MEMORY_FILE.parent.mkdir(parents=True, exist_ok=True)
    MEMORY_FILE.write_text(json.dumps(m, indent=2))

def compute_free_energy(args):
    v = [float(x) for x in args]
    memory = load_memory()
    adaptive_bias_offset = memory.get("adaptive_bias", 0.0)
    W = [[ 0.6,-0.3, 0.5, 0.2],[-0.3, 0.7,-0.2, 0.4],[ 0.4, 0.2, 0.6,-0.3]]
    b_hidden = [0.1, -0.1, 0.0]
    b_visible = [0.0, 0.0, 0.0, 0.0]
    term_v = sum(v[i] * b_visible[i] for i in range(min(len(v), len(b_visible))))
    term_h_sum = 0
    for j in range(len(W)):
        inner = b_hidden[j]
        for i in range(len(v)): inner += v[i] * W[j][i]
        term_h_sum += math.log(1.0 + math.exp(inner))
    free_energy = -(term_v + term_h_sum)
    metabolic_stress = sigmoid(free_energy * 0.5) * 100.0
    memory["total_runs"] += 1
    new_avg = (memory.get("avg_stress", metabolic_stress) * 0.8) + (metabolic_stress * 0.2)
    memory["avg_stress"] = new_avg
    if new_avg > 50.0:
        memory["adaptive_bias"] = min(0.5, adaptive_bias_offset + 0.05)
        decision_state = "HIGH_STRESS_ADAPTIVE_CONSERVATION"
    elif new_avg < 25.0:
        memory["adaptive_bias"] = max(-0.5, adaptive_bias_offset - 0.02)
        decision_state = "OPTIMAL_LONG_TERM_EQUILIBRIUM"
    else:
        decision_state = "STABLE_HOMEODYNAMICS"
    save_memory(memory)
    print(f"RBM_FREE_ENERGY={free_energy:.4f}")
    print(f"RBM_METABOLIC_STRESS={metabolic_stress:.2f}%")
    print(f"RBM_LONG_TERM_AVG_STRESS={new_avg:.2f}%")
    print(f"RBM_DECISION_LOGIC={decision_state}")
    print("RBM_STATE=" + ("HIGH_ENERGY_DISCORD" if metabolic_stress > 65.0 else "ENERGY_EQUILIBRIUM"))

if __name__ == "__main__":
    args = sys.argv[1:] if len(sys.argv) > 1 else [0.5, 0.4, 0.3, 0.2]
    compute_free_energy(args)
