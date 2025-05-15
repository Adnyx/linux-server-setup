#!/usr/bin/env bash
# NFS Server Setup Script
# Sets up /srv/nfs/public shared with 10.42.0.0/24


# /!\\
# MAKE SURE TO CHANGE THE NETWORK ADDRESS IN THE 'EXPORT_LINE' LINE !!!!!




set -euo pipefail

# Install and start NFS server
dnf install -y nfs-utils
systemctl enable --now nfs-server

# Create shared directory
mkdir -p /srv/nfs/public
chown nobody:nobody /srv/nfs/public
chmod 755 /srv/nfs/public

# Add export entry (if not already present)
EXPORT_LINE="/srv/nfs/public 10.42.0.0/24(rw,sync,no_root_squash,no_subtree_check)"
grep -qxF "$EXPORT_LINE" /etc/exports || echo "$EXPORT_LINE" >> /etc/exports

# Apply export rules
exportfs -rav

# Open firewall for NFS
echo "Adding nfs to firewall service"
firewall-cmd --permanent --add-service=nfs
echo "Reloading firewall"
firewall-cmd --reload

echo "NFS server setup complete."
