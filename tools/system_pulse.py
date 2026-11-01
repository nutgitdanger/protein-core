import os
import shutil
import sys

def check_pulse():
    print("=== PROTEIN SYSTEM PULSE ===")
    total, used, free = shutil.disk_usage("/data")
    print(f"พื้นที่เก็บข้อมูลทั้งหมด: {total // (2**30)} GB")
    print(f"ใช้งานไปแล้ว: {used // (2**30)} GB")
    print(f"พื้นที่ว่าง: {free // (2**30)} GB")
    
    current_dir = os.getcwd()
    print(f"ไดเรกทอรีปัจจุบัน: {current_dir}")

if __name__ == "__main__":
    check_pulse()
