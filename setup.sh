#!/usr/bin/env bash
# ==========================================
# This is the whole setup script.
# Make sure to read the README file before executing
# ==========================================

set -euo pipefail

$CRON_FILE="Backups/cron-config.txt"

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use sudo)" >&2
  exit 1
fi

# Check that a flag was provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [-m | -b]"
    echo "  -m : setup main server"
    echo "  -b : setup backup server"
    exit 1
fi

# Run for both MAIN and BACKUP server
./requirements-setup.sh

# ASKING for RAID1 setup
while true; do
    read -rp "Do you want to set up RAID1 ? (y/n): " answer
    case "$answer" in
        [Yy]*)
            echo "Running setup for RAID1..."
            ./Backups/raid1-setup.sh
            ./Backups/raid1-status-check.sh
            break
            ;;
        [Nn]*)
            echo "Aight bet, skipping this."
            break
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done


# ASKING for monitoring setup
while true; do
    read -rp "Do you want to set up Monitoring (prometheus and grafana)? (y/n): " answer
    case "$answer" in
        [Yy]*)
            echo "Running setup for monitoring..."
            ./Monitoring/monitoring-setup.sh
            break
            ;;
        [Nn]*)
            echo "Aight bet, skipping this."
            break
            ;;
        *)
            echo "Please answer y or n."
            ;;
    esac
done


# Then handle role-specific setup
case "$1" in
    -m)
        echo "Setting up MAIN server..."
       	echo "Creating safe project folder for backups"
        mkdir -p /opt/backup
	cp backup-script.sh /opt/backup/
	chmod +x /opt/backup/backup-script.sh
	
        ./Backups/backup-script.sh
        ./Backups/FTP/ftp-main-server.sh
        ./NFS/nfs-main-server.sh
        ./NTP/ntp-main-server.sh
        ( crontab -l 2>/dev/null; cat "$CRON_FILE" ) | crontab -
    	echo "Crontab updated."
        ;;
    -b)
        echo "Setting up BACKUP server..."
	./Backups/FTP/ftp-backup-server.sh
	./NFS/nfs-clients.sh
	./NTP/ntp-clients.sh
        ;;
    *)
        echo "Unknown option: $1"
        exit 1
        ;;
esac





