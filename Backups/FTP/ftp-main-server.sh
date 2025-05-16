ssh-keygen -t rsa -b 4096 -f ~/.ssh/backup_key
ssh-copy-id -i ~/.ssh/backup_key.pub backups@10.42.0.49

ssh -i ~/.ssh/backup_key backups@10.42.0.49

# 2 and copy the key
cat ~/.ssh/backup_key.pub


scp -i ~/.ssh/backup_key /srv/backups/*.gpg backups@10.42.0.49:/mnt/raid/backups-from-main/
