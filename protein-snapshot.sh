#!/usr/bin/env zsh
# =====================================================================
# 🧬 PROTEIN SYSTEM: ARCHITECTURAL SNAPSHOT & MEMORY BANK
# =====================================================================

clear
print "====================================================================="
print "        🧬 PROTEIN ECOSYSTEM — ARCHITECTURAL MEMORY BANK"
print "====================================================================="
print "[ROOT DIRECTORY] : $HOME/protein-core"
print "[CLOUD SUBSTRATE]: AWS EC2 (m7) + DynamoDB + S3 Vault"
print "[SHIELD STATUS]  : $(cat $HOME/protein-core/shield.state 2>/dev/null || echo 'UNKNOWN')"
print "---------------------------------------------------------------------"
print "📂 [CORE METABOLIC STATE]"
if [[ -f "$HOME/protein-core/metabolism.state" ]]; then
    print "  • $(cat $HOME/protein-core/metabolism.state)"
else
    print "  • Status: Stable / 0K Idle"
fi
print "---------------------------------------------------------------------"
print "⚙️ [PIPELINE & QUEUE LINEAGE]"
print "  • Pending Jobs   : $(ls -1 $HOME/protein-core/pipeline/pending 2>/dev/null | wc -l)"
print "  • Processing     : $(ls -1 $HOME/protein-core/pipeline/processing 2>/dev/null | wc -l)"
print "  • Completed      : $(ls -1 $HOME/protein-core/pipeline/completed 2>/dev/null | wc -l)"
print "  • Failed         : $(ls -1 $HOME/protein-core/pipeline/failed 2>/dev/null | wc -l)"
print "---------------------------------------------------------------------"
print "🧬 [KEY CATALYSTS & ENGINES (Unified)]"
print "  • Master Brain   : protein-master-controller.zsh"
print "  • Gateway/Safety : protein-admission-gate.zsh / protein-safety-gate.zsh"
print "  • Core Engines   : protein-engine.sh / protein-pipeline.sh / protein-worker.sh"
print "  • Evolution Labs : protein-bounded-evolution.sh / protein-dna.sh"
print "====================================================================="
print "💡 TIP: พิมพ์ './protein-snapshot.sh' เพื่อเรียกภาพจำนี้ขึ้นมาดูได้ตลอดเวลา"
print "====================================================================="
