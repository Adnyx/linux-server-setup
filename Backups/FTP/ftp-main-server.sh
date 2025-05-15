#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BACKUP_IP=$(cat "$SCRIPT_DIR/backup-server-ip.txt")
MAIN_IP=$(cat "$SCRIPT_DIR/main-server-ip.txt")

ssh-keygen -t rsa -b 4096 -f ~/.ssh/backup_key
ssh-copy-id -i ~/.ssh/backup_key.pub backups@$BACKUP_IP

ssh -i ~/.ssh/backup_key backups@$BACKUP_IP

# 2 and copy the key
cat ~/.ssh/backup_key.pub


scp -i ~/.ssh/backup_key /srv/backups/*.gpg backups@$BACKUP_IP:/mnt/raid/backups-from-main/
