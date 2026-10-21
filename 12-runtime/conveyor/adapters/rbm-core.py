#!/data/data/com.termux/files/usr/bin/python3
import sys
import math

def sigmoid(x):
    if x < -709: return 0.0
    if x > 709: return 1.0
    return 1.0 / (1.0 + math.exp(-x))

def compute_free_energy(visible_units):
    # Visible units: [CPU_Load_Ratio, RAM_Pressure, Voltage_Stress, Battery_Drain]
    v = [float(x) for x in visible_units]
    
    # RBM Weights Matrix (Hidden x Visible) & Biases
    # ออกแบบให้น้ำหนักเชื่อมโยงกับพฤติกรรมความร้อนและพลังงานของฮาร์ดแวร์ 8-core
    W = [
        [ 0.6, -0.3,  0.5,  0.2],
        [-0.3,  0.7, -0.2,  0.4],
        [ 0.4,  0.2,  0.6, -0.3]
    ]
    b_hidden = [0.1, -0.1, 0.0]
    b_visible = [0.0, 0.0, 0.0, 0.0]
    
    # 1. Forward Pass: คำนวณความน่าจะเป็นและความกระตุ้นของ Hidden Units
    h_activations = []
    for j in range(len(W)):
        act = b_hidden[j]
        for i in range(len(v)):
            act += v[i] * W[j][i]
        h_activations.append(sigmoid(act))
        
    # 2. Free Energy Calculation: F(v) = - v*b_v - sum( log(1 + exp(b_h + W*v)) )
    term_v = sum(v[i] * b_visible[i] for i in range(min(len(v), len(b_visible))))
    term_h_sum = 0
    for j in range(len(W)):
        inner = b_hidden[j]
        for i in range(len(v)):
            inner += v[i] * W[j][i]
        term_h_sum += math.log(1.0 + math.exp(inner))
        
    free_energy = -(term_v + term_h_sum)
    
    # แปลง Free Energy เป็น Metabolic Stress Index (0% - 100%)
    metabolic_stress = sigmoid(free_energy * 0.5) * 100.0
    
    print(f"RBM_FREE_ENERGY={free_energy:.4f}")
    print(f"RBM_METABOLIC_STRESS={metabolic_stress:.2f}%")
    if metabolic_stress > 65.0:
        print("RBM_STATE=HIGH_ENERGY_DISCORD")
    else:
        print("RBM_STATE=ENERGY_EQUILIBRIUM")

if __name__ == "__main__":
    # รับค่า Visible Units จาก Argument หรือใช้ค่าเริ่มต้น
    args = sys.argv[1:] if len(sys.argv) > 1 else [0.5, 0.4, 0.3, 0.2]
    compute_free_energy(args)
