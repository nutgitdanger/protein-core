#!/usr/bin/env python3
"""เทียบ CA ของสองโครงสร้าง (PDB) ด้วย RMSD หลัง superposition (Kabsch)

ใช้: python3 tools/rmsd_check.py exp.pdb pred.pdb [pLDDT_min=70]
- exp.pdb  = โครงสร้างจากการทดลอง (เช่น 1UBQ จาก RCSB)
- pred.pdb = โครงสร้างทำนายจาก AlphaFold DB (pLDDT อยู่ที่คอลัมน์ B-factor)
ต้องใช้ numpy: รันบน EC2 หรือคอมพิวเตอร์ ไม่ใช่โทรศัพท์
"""
import sys
import numpy as np


def read_ca(path):
    res = {}
    with open(path) as f:
        for line in f:
            if not line.startswith("ATOM"):
                continue
            if line[12:16].strip() != "CA" or line[16] not in (" ", "A"):
                continue
            num = int(line[22:26])
            xyz = np.array([float(line[30:38]), float(line[38:46]), float(line[46:54])])
            b = float(line[60:66])
            res[num] = (xyz, b)
    return res


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    exp = read_ca(sys.argv[1])
    pred = read_ca(sys.argv[2])
    cut = float(sys.argv[3]) if len(sys.argv) > 3 else 70.0

    common = sorted(k for k in exp if k in pred and pred[k][1] > cut)
    if len(common) < 10:
        sys.exit(f"ERROR: เหลือ CA ที่ใช้ได้ {len(common)} ตัว น้อยเกินไป ตรวจ pLDDT หรือหมายเลขกรดอะมิโน")

    P = np.array([pred[k][0] for k in common])
    Q = np.array([exp[k][0] for k in common])
    Pc = P - P.mean(axis=0)
    Qc = Q - Q.mean(axis=0)

    H = Pc.T @ Qc
    U, S, Vt = np.linalg.svd(H)
    d = np.sign(np.linalg.det(Vt.T @ U.T))
    R = Vt.T @ np.diag([1.0, 1.0, d]) @ U.T

    diff = Pc @ R.T - Qc
    rmsd = np.sqrt((diff ** 2).sum(axis=1).mean())

    print(f"residues used: {len(common)} (pLDDT > {cut})")
    print(f"RMSD after superposition: {rmsd:.3f} A")
    print("หมายเหตุ: ค่านี้วัดความคล้ายโครงสร้าง ไม่ได้พิสูจน์ว่าระบบของเราถูกต้อง")


if __name__ == "__main__":
    main()
