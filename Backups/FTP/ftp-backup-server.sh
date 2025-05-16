sudo useradd backups

sudo mkdir -p /mnt/raid/backups-from-main
sudo chown backups: /mnt/raid/backups-from-main

# 1
id backups
sudo mkdir -p /home/backups/.ssh
sudo touch /home/backups/.ssh/authorized_keys
sudo chown -R backups:backups /home/backups/.ssh
sudo chmod 700 /home/backups/.ssh
sudo chmod 600 /home/backups/.ssh/authorized_keys

# 3 and paste the key
sudo nano /home/backups/.ssh/authorized_keys

