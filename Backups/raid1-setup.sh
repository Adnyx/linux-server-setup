#!/usr/bin/env bash
# ==========================================
#  RAID 1 Setup Script for Backup Server
#  WARNING: This will erase all data on /dev/nvme1n1 and /dev/nvme2n1
# ==========================================

set -euo pipefail

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use sudo)" >&2
  exit 1
fi

# Install mdadm if not already installed
dnf install -y mdadm

# Optional: Show block devices for verification
lsblk

# Create the RAID 1 array
mdadm --create --verbose /dev/md0 \
  --level=1 \
  --raid-devices=2 /dev/nvme1n1 /dev/nvme2n1

# Show array sync progress
cat /proc/mdstat

# Create ext4 filesystem on the RAID device
mkfs.ext4 /dev/md0

# Create mount point and mount it
mkdir -p /mnt/raid
mount /dev/md0 /mnt/raid

# Save RAID config to mdadm.conf
mdadm --detail --scan | tee -a /etc/mdadm.conf

# Print UUID for /etc/fstab setup
echo -e "\n--> Copy the UUID below into /etc/fstab manually:"
blkid /dev/md0

echo -e "\nSuggested /etc/fstab entry (replace UUID accordingly):"
echo "UUID=xxxx-xxxx-xxxx-xxxx /mnt/raid ext4 defaults,nofail 0 2"

# Done!
echo -e "RAID 1 is set up and mounted on /mnt/raid"

