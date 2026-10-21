#!/usr/bin/env zsh
set -uo pipefail

run_deep_sense() {
    print "====================================================================="
    print "       🔬 PROTEIN DEEP KERNEL & HOST SENSORY TRANSCRIBER"
    print "====================================================================="

    # 1. คำนวณ Synthetic Load Average จากความถี่จริงของ 8 คอร์
    local total_mhz=0
    local active_cores=0
    for cpu_dir in /sys/devices/system/cpu/cpu[0-7](N); do
        [[ -d "$cpu_dir" ]] || continue
        local freq_file="$cpu_dir/cpufreq/scaling_cur_freq"
        if [[ -r "$freq_file" ]]; then
            local freq=$(cat "$freq_file" 2>/dev/null)
            if [[ -n "$freq" ]]; then
                total_mhz=$(( total_mhz + (freq / 1000) ))
                active_cores=$(( active_cores + 1 ))
            fi
        fi
    done

    if [[ $active_cores -gt 0 ]]; then
        local avg_mhz=$(( total_mhz / active_cores ))
        print "🌍 [SYNTHETIC HOST LOAD] Active Cores: $active_cores/8 | Avg Frequency: ${avg_mhz} MHz"
    else
        print "🌍 [SYNTHETIC HOST LOAD] Core frequencies locked by sandbox."
    fi

    # 2. ตรวจสอบความถี่จริงของ 8 คอร์
    print "⚡ [8-CORE HARDWARE FREQUENCY MAPPING]"
    for cpu_dir in /sys/devices/system/cpu/cpu[0-7](N); do
        [[ -d "$cpu_dir" ]] || continue
        local core_name=$(basename "$cpu_dir")
        local freq_file="$cpu_dir/cpufreq/scaling_cur_freq"
        
        if [[ -r "$freq_file" ]]; then
            local freq=$(cat "$freq_file" 2>/dev/null)
            if [[ -n "$freq" ]]; then
                local mhz=$(( freq / 1000 ))
                if [[ "$core_name" =~ "[4-7]" ]]; then
                    print "   🔥 [Performance Core $core_name - Cortex-A73] : ${mhz} MHz"
                else
                    print "   🌱 [Efficiency Core $core_name - Cortex-A53] : ${mhz} MHz"
                fi
                continue
            fi
        fi
    done

    # 3. ตรวจสอบหน่วยความจำระบบเชิงลึก
    if [[ -f /proc/meminfo ]]; then
        local total_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local avail_kb=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        if [[ -n "$total_kb" && -n "$avail_kb" ]]; then
            local total_mb=$(( total_kb / 1024 ))
            local avail_mb=$(( avail_kb / 1024 ))
            print "🧠 [HOST MEMORY DEEP SCAN]"
            print "   ├── Total System RAM : ${total_mb} MB"
            print "   └── Available RAM    : ${avail_mb} MB"
        fi
    fi

    print "====================================================================="
    print "💤 [DEEP SENSE] Kernel anatomy mapped. Returning to 0K idle."
}

run_deep_sense
