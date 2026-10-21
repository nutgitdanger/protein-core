#!/data/data/com.termux/files/usr/bin/zsh
set -euo pipefail

PIPE_ROOT="$HOME/protein-core/pipeline"
LOG_DIR="$HOME/protein-core/logs"
mkdir -p "$LOG_DIR" "$PIPE_ROOT"/{pending,processing,completed,failed}

PENDING="$PIPE_ROOT/pending"
PROCESSING="$PIPE_ROOT/processing"
COMPLETED="$PIPE_ROOT/completed"
FAILED="$PIPE_ROOT/failed"

job_file=$(find "$PENDING" -maxdepth 1 -name "*.json" | sort | head -n 1)

if [[ -z "$job_file" ]]; then
    print "⚪ [PIPELINE] No work items. 0 K idle state."
    exit 0
fi

job_name=$(basename "$job_file")
work_path="$PROCESSING/$job_name"

# ย้ายงานมาล็อกสถานะ (Atomic Lock)
mv "$job_file" "$work_path"
print "🟢 [PIPELINE] Executing pipeline task: $job_name"

# ดึงชื่อ executor และ task จาก JSON
if python3 -c "import json; d=json.load(open('$work_path')); assert 'task' in d" 2>/dev/null; then
    task_type=$(python3 -c "import json; print(json.load(open('$work_path'))['task'])")
    executor=$(python3 -c "import json; d=json.load(open('$work_path')); print(d.get('executor', ''))")
    
    print "⚙️ [PIPELINE] Routed task: $task_type (Executor: ${executor:-None})"
    
    # ถ้ามีการระบุ executor script จริง ให้สั่งรันและเก็บ Log
    if [[ -n "$executor" && -f "$HOME/protein-core/$executor" ]]; then
        print "🚀 [PIPELINE] Running actual protein script: $executor"
        "$HOME/protein-core/$executor" >> "$LOG_DIR/pipeline_exec.log" 2>&1 || true
    fi

    # ทำงานสำเร็จ ย้ายไป completed
    mv "$work_path" "$COMPLETED/$job_name"
    print "✅ [PIPELINE] Task $job_name completed and archived."
else
    mv "$work_path" "$FAILED/$job_name"
    print "❌ [PIPELINE] Task $job_name failed schema validation."
fi
