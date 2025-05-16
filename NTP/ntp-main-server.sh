echo "pool 2.centos.pool.ntp.org iburst" >> /etc/chrony.conf
echo "allow 10.42.0.0/24" >> /etc/chrony.conf
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
# To check the line above
sudo firewall-cmd --list-all | grep ntp
sudo systemctl restart chronyd

sudo timedatectl set-timezone Europe/Brussels
