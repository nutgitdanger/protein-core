#!/usr/bin/env bash
# =====================================================================
#  🧬 PROTEIN ECOSYSTEM: ENGINE & VAULT S3 FULL SYNC
# =====================================================================

REMOTE_S3="aws:nutgit-vault-178870258461-ap-southeast-7/protein-engine-cluster"
BACKUP_DIR="$HOME/dynu-environment/backup"
BACKUP_TAR="$BACKUP_DIR/protein-engine-full-backup.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "[*] Packaging local engine, scripts, and SQLite vault..."
tar -czf "$BACKUP_TAR" \
    --exclude=".git" \
    --exclude="node_modules" \
    --exclude="backup" \
    -C "$HOME" dynu-environment \
    .config/dynu-audit

echo "[*] Uploading heavy engine package to AWS S3 (ap-southeast-7)..."
rclone copy "$BACKUP_TAR" "$REMOTE_S3/" --progress

echo "[✓] Protein Engine & Vault successfully offloaded and secured on S3!"
