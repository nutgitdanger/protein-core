#!/data/data/com.termux/files/usr/bin/python3
import sys
import math
import os
import json
from datetime import datetime

MEMORY_FILE = os.path.expanduser("~/protein-core/pipeline/.neural_memory_history.json")

def sigmoid(x):
    if x < -709: return 0.0
    if x > 709: return 1.0
    return 1.0 / (1.0 + math.exp(-x))

def load_long_term_memory():
    if os.path.exists(MEMORY_FILE):
        try:
            with open(MEMORY_FILE, 'r') as f:
                return json.load(f)
        except:
            pass
    return {"total_runs": 0, "avg_stress": 20.0, "adaptive_bias": 0.0}

def save_long_term_memory(memory):
    os.makedirs(os.path.dirname(MEMORY_FILE), exist_ok=True)
    with open(MEMORY_FILE, 'w') as f:
        json.dump(memory, f, indent=2)

def compute_free_energy(visible_units):
    v = [float(x) for x in visible_units]
    
    # โหลดความจำระยะยาวมาปรับค่า Bias แบบ Adaptive Learning
    memory = load_long_term_memory()
    adaptive_bias_offset = memory.get("adaptive_bias", 0.0)
    
    W = [
        [ 0.6, -0.3,  0.5,  0.2],
        [-0.3,  0.7, -0.2,  0.4],
        [ 0.4,  0.2,  0.6, -0.3]
    ]
    # นำความจำระยะยาวมามีส่วนร่วมในการตัดสินใจ (Long-term homeostasis bias)
    b_hidden = [0.1 + adaptive_bias_offset, -0.1, 0.0]
    b_visible = [0.0, 0.0, 0.0, 0.0]
    
    # Forward Pass
    h_activations = []
    for j in range(len(W)):
        act = b_hidden[j]
        for i in range(len(v)):
            act += v[i] * W[j][i]
        h_activations.append(sigmoid(act))
        
    # Free Energy Calculation
    term_v = sum(v[i] * b_visible[i] for i in range(min(len(v), len(b_visible))))
    term_h_sum = 0
    for j in range(len(W)):
        inner = b_hidden[j]
        for i in range(len(v)):
            inner += v[i] * W[j][i]
        term_h_sum += math.log(1.0 + math.exp(inner))
        
    free_energy = -(term_v + term_h_sum)
    metabolic_stress = sigmoid(free_energy * 0.5) * 100.0
    
    # --- LONG-TERM LEARNING & ADAPTATION ---
    memory["total_runs"] += 1
    # คำนวณค่าเฉลี่ยความเครียดสะสมแบบ Exponential Moving Average
    prev_avg = memory.get("avg_stress", metabolic_stress)
    new_avg = (prev_avg * 0.8) + (metabolic_stress * 0.2)
    memory["avg_stress"] = new_avg
    
    # ตรรกะตัดสินใจระยะยาว: หากระบบเครียดสะสมสูงเกินไป ปรับ Bias ให้ระบบระมัดระวังขึ้นอัตโนมัติ
    if new_avg > 50.0:
        memory["adaptive_bias"] = min(0.5, adaptive_bias_offset + 0.05)
        decision_state = "HIGH_STRESS_ADAPTIVE_CONSERVATION"
    elif new_avg < 25.0:
        memory["adaptive_bias"] = max(-0.5, adaptive_bias_offset - 0.02)
        decision_state = "OPTIMAL_LONG_TERM_EQUILIBRIUM"
    else:
        decision_state = "STABLE_HOMEODYNAMICS"
        
    save_long_term_memory(memory)
    
    print(f"RBM_FREE_ENERGY={free_energy:.4f}")
    print(f"RBM_METABOLIC_STRESS={metabolic_stress:.2f}%")
    print(f"RBM_LONG_TERM_AVG_STRESS={new_avg:.2f}%")
    print(f"RBM_DECISION_LOGIC={decision_state}")
    if metabolic_stress > 65.0:
        print("RBM_STATE=HIGH_ENERGY_DISCORD")
    else:
        print("RBM_STATE=ENERGY_EQUILIBRIUM")

if __name__ == "__main__":
    args = sys.argv[1:] if len(sys.argv) > 1 else [0.5, 0.4, 0.3, 0.2]
    compute_free_energy(args)
