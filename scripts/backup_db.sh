#!/usr/bin/env bash
# ============================================================
# Hisob Finance - PostgreSQL Automated Backup Script
# Usage: ./scripts/backup_db.sh
# Requires: POSTGRES_USER, POSTGRES_DB, DB_HOST env vars
# ============================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/backups}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_NAME="${POSTGRES_DB:-finance_db}"
DB_USER="${POSTGRES_USER:-finance_user}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

mkdir -p "$BACKUP_DIR"

BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "[$(date)] Starting backup of database '$DB_NAME'..."

pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    --no-owner --no-acl --format=plain | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup successful: $BACKUP_FILE ($FILE_SIZE)"
else
    echo "[$(date)] ERROR: Backup failed!" >&2
    exit 1
fi

# Clean up old backups
echo "[$(date)] Cleaning backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime "+$RETENTION_DAYS" -delete

echo "[$(date)] Backup complete."
