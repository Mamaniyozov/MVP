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

# GPG Encryption
if [ -n "${GPG_RECIPIENT:-}" ]; then
    echo "[$(date)] Encrypting backup with GPG for $GPG_RECIPIENT..."
    gpg --batch --yes --trust-model always -e -r "$GPG_RECIPIENT" "$BACKUP_FILE"
    # Remove unencrypted file if encryption succeeded
    if [ $? -eq 0 ]; then
        rm "$BACKUP_FILE"
        BACKUP_FILE="${BACKUP_FILE}.gpg"
    else
        echo "[$(date)] ERROR: GPG encryption failed!" >&2
        exit 1
    fi
fi

if [ $? -eq 0 ]; then
    FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup successful: $BACKUP_FILE ($FILE_SIZE)"
    
    if [ -n "${AWS_S3_BUCKET:-}" ]; then
        echo "[$(date)] Uploading to S3 bucket $AWS_S3_BUCKET with AES256 encryption..."
        aws s3 cp "$BACKUP_FILE" "s3://$AWS_S3_BUCKET/db_backups/" --sse AES256
        if [ $? -eq 0 ]; then
            echo "[$(date)] S3 Upload successful."
        else
            echo "[$(date)] ERROR: S3 Upload failed!" >&2
        fi
    fi
else
    echo "[$(date)] ERROR: Backup failed!" >&2
    exit 1
fi

# Clean up old backups
echo "[$(date)] Cleaning backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime "+$RETENTION_DAYS" -delete
find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz.gpg" -mtime "+$RETENTION_DAYS" -delete

echo "[$(date)] Backup complete."
