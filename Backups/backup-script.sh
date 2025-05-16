#!/usr/bin/env bash
# =========================================================
#  Encrypted Backup Script
#  Creates full/incremental backups and sends to backup server
# =========================================================

set -euo pipefail

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use: sudo $0"
    exit 1
fi

# ---------- CONFIGURATION ---------------------------------
BACKUP_ROOT="/tmp/backup"
SRC_DIRS=("/srv" "/var" "/home" "/users")
SNAPSHOT_FILE="$BACKUP_ROOT/snapshot.snar"

# MAKE SURE TO PUT THE EMAIL YOU'LL USE FOR GPG BELOW
GPG_RECIPIENT="YOUR EMAIL"
FULL_DAY="Sunday"
RETENTION_DAYS=7
DATE=$(date +%F)
HOST=$(hostname -s)
ARCHIVE_NAME="${HOST}_${DATE}"
LOG_FILE="/var/log/backup.log"

REMOTE_USER="backups"
REMOTE_HOST="10.42.0.234"
REMOTE_DIR="/mnt/raid/backups-from-main"
SSH_KEY="/home/ec2-user/.ssh/backup_key"

# ---------- PREP ------------------------------------------
mkdir -p "$BACKUP_ROOT"
exec >>"$LOG_FILE" 2>&1
echo "[${DATE}] Starting backup…"

# ---------- FULL or INCREMENTAL ---------------------------
if [[ "$(date +%A)" == "$FULL_DAY" ]] || [[ ! -f "$SNAPSHOT_FILE" ]]; then
    TYPE="full"
    ARCHIVE_NAME+="_full.tar.gz.gpg"
else
    TYPE="inc"
    ARCHIVE_NAME+="_inc.tar.gz.gpg"
fi

echo "Creating $TYPE backup → $ARCHIVE_NAME"

# ---------- BACKUP CREATION -------------------------------
tar -czf - --listed-incremental="$SNAPSHOT_FILE" "${SRC_DIRS[@]}" \
  | gpg --batch --yes --trust-model always --encrypt --recipient "$GPG_RECIPIENT" \
  --output "$BACKUP_ROOT/$ARCHIVE_NAME"

echo "Backup created: $BACKUP_ROOT/$ARCHIVE_NAME"

# ---------- TRANSFER TO BACKUP SERVER ---------------------
scp -i "$SSH_KEY" "$BACKUP_ROOT/$ARCHIVE_NAME" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

echo "Backup transferred to $REMOTE_HOST"

# ---------- RETENTION CLEANUP -----------------------------
find "$BACKUP_ROOT" -type f -name "*.tar.gz.gpg" -mtime +"$RETENTION_DAYS" -print -delete
echo "Old backups older than $RETENTION_DAYS days removed."

echo "Backup job completed successfully."

