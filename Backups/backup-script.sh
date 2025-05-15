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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKUP_IP=$(cat "$SCRIPT_DIR/../backup-server-ip.txt")
MAIN_IP=$(cat "$SCRIPT_DIR/../main-server-ip.txt")

BACKUP_ROOT="/tmp/backup"
SRC_DIRS=("/srv" "/var" "/home" "/users")
SNAPSHOT_FILE="$BACKUP_ROOT/snapshot.snar"
GPG_RECIPIENT="theo.dubois@std.heh.be"
FULL_DAY="Sunday"
RETENTION_DAYS=7
DATE=$(date +%F)
HOST=$(hostname -s)
ARCHIVE_NAME="${HOST}_${DATE}"
LOG_FILE="/var/log/backup.log"

REMOTE_USER="backups"
REMOTE_HOST=$BACKUP_IP
REMOTE_DIR="/mnt/raid/backups-from-main"
SSH_KEY="/home/ec2-user/.ssh/backup_key"

# ---------- PREP ------------------------------------------
mkdir -p /users

echo "making backup directory"
export GPG_TTY=$(tty 2>/dev/null || echo "not-a-tty")
mkdir -p "$BACKUP_ROOT"

sudo mkdir -p /var/log/
sudo touch /var/log/backup.log
sudo chown ec2-user:ec2-user /var/log/backup.log

exec >>"$LOG_FILE" 2>&1
echo "[${DATE}] Starting backup…"

# ---------- FULL or INCREMENTAL ---------------------------
if [[ "$(date +%A)" == "$FULL_DAY" ]] || [[ ! -f "$SNAPSHOT_FILE" ]]; then
    TYPE="full"
    ARCHIVE_NAME+="_full.tar.gz.gpg"
    echo "full backup day! :3"
else
    TYPE="inc"
    ARCHIVE_NAME+="_inc.tar.gz.gpg"
    echo "incremental backup day! :3"
fi

echo "Creating $TYPE backup → $ARCHIVE_NAME"

# ---------- BACKUP CREATION -------------------------------
tar cz "${SRC_DIRS[@]}" | gpg --yes --batch --auto-key-locate=local --encrypt --recipient "$GPG_RECIPIENT" -o "$ARCHIVE"


echo "Backup created: $BACKUP_ROOT/$ARCHIVE_NAME"

# ---------- TRANSFER TO BACKUP SERVER ---------------------
scp -i "$SSH_KEY" "$BACKUP_ROOT/$ARCHIVE_NAME" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"

echo "Backup transferred to $REMOTE_HOST"

# ---------- RETENTION CLEANUP -----------------------------
find "$BACKUP_ROOT" -type f -name "*.tar.gz.gpg" -mtime +"$RETENTION_DAYS" -print -delete
echo "Old backups older than $RETENTION_DAYS days removed."

echo "Backup job completed successfully."

