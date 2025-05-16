#!/usr/bin/env bash
set -euo pipefail

# === Download and install Prometheus ===
wget https://github.com/prometheus/prometheus/releases/download/v2.46.0/prometheus-2.46.0.linux-amd64.tar.gz
tar -xvzf prometheus-2.46.0.linux-amd64.tar.gz
cd prometheus-2.46.0.linux-amd64

mv prometheus /usr/local/bin/
mv promtool /usr/local/bin/
rm -rf /etc/prometheus/consoles
mv consoles /etc/prometheus
rm -rf /etc/prometheus/console_libraries
mv console_libraries /etc/prometheus
cd ..

# === Prometheus configuration ===
tee /etc/prometheus/prometheus.yml > /dev/null <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

# === Prometheus systemd service ===
tee /etc/systemd/system/prometheus.service > /dev/null <<EOF
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/prometheus \\
  --config.file=/etc/prometheus/prometheus.yml \\
  --storage.tsdb.path=/var/lib/prometheus/data \\
  --web.console.templates=/etc/prometheus/consoles \\
  --web.console.libraries=/etc/prometheus/console_libraries
User=prometheus
Group=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now prometheus

# === Open necessary firewall ports ===
firewall-cmd --permanent --add-port=9090/tcp
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --reload

# === Install Grafana ===
wget https://dl.grafana.com/oss/release/grafana-9.2.0-1.x86_64.rpm
dnf install -y ./grafana-9.2.0-1.x86_64.rpm
systemctl enable --now grafana-server

# === node_exporter setup ===
wget https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz
tar -xvzf node_exporter-1.3.1.linux-amd64.tar.gz
cd node_exporter-1.3.1.linux-amd64
mv node_exporter /usr/local/bin/
cd ..

# Start node_exporter in background (optional: systemd unit recommended for production)
nohup /usr/local/bin/node_exporter > /dev/null 2>&1 &

