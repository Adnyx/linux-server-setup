echo "server 10.42.0.102 iburst" >> /etc/chrony.conf
systemctl restart chronyd

sudo timedatectl set-timezone Europe/Brussels
