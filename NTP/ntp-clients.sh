#!/usr/bin/bash

BACKUP_IP=$(cat "$SCRIPT_DIR/backup-server-ip.txt")
MAIN_IP=$(cat "$SCRIPT_DIR/main-server-ip.txt")

echo "server $MAIN_IP iburst" >> /etc/chrony.conf
systemctl restart chronyd

sudo timedatectl set-timezone Europe/Brussels
