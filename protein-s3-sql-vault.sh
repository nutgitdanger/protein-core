#!/usr/bin/env bash
# =====================================================================
#  🧬 PROTEIN ECOSYSTEM: S3 LIGHTWEIGHT SQL VAULT ENGINE
# =====================================================================

VAULT_DIR="$HOME/.config/dynu-audit/vault"
DB_FILE="$VAULT_DIR/protein_index.db"

# ชี้รีโมตไปที่ aws และล็อกโหมดความปลอดภัยของโฟลเดอร์ vault
S3_REMOTE="aws:nutgit-vault-178870258461-ap-southeast-7/protein-vault"

mkdir -p "$VAULT_DIR"
chmod 700 "$VAULT_DIR"

case "$1" in
    init)
        echo "[*] Initializing SQLite Light Index Vault..."
        sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS memory_index (id INTEGER PRIMARY KEY, key TEXT, payload TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP);"
        chmod 600 "$DB_FILE"
        echo "[✓] Local SQL Vault initialized and secured at $DB_FILE"
        ;;
    
    push)
        echo "[*] Syncing local SQLite Vault to AWS S3 securely..."
        rclone copy "$DB_FILE" "$S3_REMOTE" --progress
        echo "[✓] Vault securely offloaded to S3!"
        ;;

    pull)
        echo "[*] Pulling lightweight SQLite Vault index from AWS S3..."
        rclone copy "$S3_REMOTE/protein_index.db" "$VAULT_DIR" --progress
        chmod 600 "$DB_FILE"
        echo "[✓] Vault synchronized and secured successfully!"
        ;;

    query)
        shift
        QUERY_KEY="$1"
        if [ -z "$QUERY_KEY" ]; then
            echo "[-] Error: Please provide a search key."
            exit 1
        fi
        echo "[🧠 SQL QUERY] Searching for: '$QUERY_KEY'..."
        sqlite3 "$DB_FILE" "SELECT payload FROM memory_index WHERE key LIKE '%$QUERY_KEY%';"
        ;;

    *)
        echo "Usage: $0 {init|push|pull|query <keyword>}"
        exit 1
        ;;
esac
