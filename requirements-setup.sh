#!/bin/bash

# ==============================================
# requirements-setup.sh
# Prepares base environment for project services
# ==============================================

set -euo pipefail

# Root check
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Please use: sudo $0"
    exit 1
fi

# ----------------------
# Base packages
# ----------------------
dnf install --allowerasing -y bind bind-utils firewalld wget curl vim net-tools unzip \
               chrony nfs-utils httpd pinentry gnupg2

# Enable services
systemctl enable --now firewalld
systemctl enable --now chronyd

# ----------------------
# Create base directories
# ----------------------
mkdir -p /users
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus
mkdir -p /srv/nfs/public
mkdir -p /home/backups

# ----------------------
# Create required users if not exist
# ----------------------
id prometheus &>/dev/null || useradd --no-create-home --shell /sbin/nologin prometheus
id grafana &>/dev/null || useradd --no-create-home --shell /sbin/nologin grafana
id backups &>/dev/null || useradd --create-home backups

# ----------------------
# Assign ownerships
# ----------------------
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown -R nobody:nobody /srv/nfs/public
chmod 755 /srv/nfs/public
chown -R backups:backups /home/backups

echo "Requirement setup completed."

