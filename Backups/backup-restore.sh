#!/usr/bin/env bash
# ======================================================
#  Fetch and restore encrypted backup from backup server
#  Usage: ./fetch-and-restore.sh <date_tag>
#         (e.g. 2025-05-13_inc or 2025-05-13_full)
# ======================================================

set -euo pipefail

# CONFIG

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKUP_IP=$(cat "$SCRIPT_DIR/backup-server-ip.txt")
MAIN_IP=$(cat "$SCRIPT_DIR/main-server-ip.txt")

BACKUP_SERVER="backups@$BACKUP_IP"
KEY_PATH="/home/ec2-user/.ssh/backup_key"
REMOTE_PATH="/mnt/raid/backups-from-main"
LOCAL_TMP="/tmp/restore"
GPG_HOME="/home/ec2-user/.gnupg"
RESTORE_TARGET="/tmp/restore_output"

# PARAM
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <date_tag> (e.g. 2025-05-13_inc)"
  exit 1
fi

TAG="$1"
FILENAME="main_server${TAG}.tar.gz.gpg"
LOCAL_ARCHIVE="$LOCAL_TMP/$FILENAME"

# Ensure local temp directories exist and are writable
mkdir -p "$LOCAL_TMP" "$RESTORE_TARGET"

if [ -w "$LOCAL_TMP" ]; then
    chmod 700 "$LOCAL_TMP"
else
    echo "Warning: Cannot set permissions on $LOCAL_TMP (insufficient rights)"
fi

echo "Fetching backup archive from backup server..."
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" "$BACKUP_SERVER:$REMOTE_PATH/$FILENAME" "$LOCAL_ARCHIVE"

echo "Decrypting and restoring..."
gpg --homedir "$GPG_HOME" --decrypt "$LOCAL_ARCHIVE" | tar -xzf - -C "$RESTORE_TARGET"

echo "Restore complete. Files available in: $RESTORE_TARGET"
