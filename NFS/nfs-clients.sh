#!/usr/bin/env bash
# NFS Client Setup Script
# Mounts 10.42.0.102:/srv/nfs/public to /mnt/nfs/public

BACKUP_IP=$(cat "$SCRIPT_DIR/backup-server-ip.txt")
MAIN_IP=$(cat "$SCRIPT_DIR/main-server-ip.txt")


set -euo pipefail

# Install NFS client utilities
dnf install -y nfs-utils

# Create the mount point
mkdir -p /mnt/nfs/public

# Mount the NFS share
mount -t nfs $MAIN_IP:/srv/nfs/public /mnt/nfs/public

# Add to fstab if not already present
FSTAB_ENTRY="$MAIN_IP:/srv/nfs/public /mnt/nfs/public nfs defaults 0 0"
grep -qxF "$FSTAB_ENTRY" /etc/fstab || echo "$FSTAB_ENTRY" >> /etc/fstab

# Apply all mounts
mount -a

echo "NFS client setup complete."
