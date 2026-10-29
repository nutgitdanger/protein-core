#!/usr/bin/env bash
# =====================================================================
#  🧬 PROTEIN ECOSYSTEM: ENGINE & VAULT S3 RESTORE
# =====================================================================

REMOTE_S3="aws:nutgit-vault-178870258461-ap-southeast-7/protein-engine-cluster"
BACKUP_DIR="$HOME/dynu-environment/backup"
BACKUP_TAR="$BACKUP_DIR/protein-engine-full-backup.tar.gz"

echo "[*] Preparing backup directory..."
mkdir -p "$BACKUP_DIR"

echo "[*] Pulling engine package from AWS S3 (ap-southeast-7)..."
rclone copy "$REMOTE_S3/protein-engine-full-backup.tar.gz" "$BACKUP_DIR/" --progress

echo "[*] Restoring and extracting engine snapshot to $HOME..."
tar -xzf "$BACKUP_TAR" -C "$HOME"

echo "[✓] Protein Engine & Vault successfully restored from AWS S3!"
