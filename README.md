# linux-server-setup
Simple linux server setup created for a school project. All of this is made for AWS since that's what we used for the project. 
You shouldn't have too many problems if you use another Redhat distro but I can't guarantee it. Have fun !

WARNING: This repo assumes that you have at least 2 servers (main and backup servers), 
take this into consideration before using.

# USAGE
Write the ip address of your main server in main-server-ip.txt
Write the ip address of your backup server in backup-server-ip.txt

Warning ! If your network address isn't 10.42.0.0/24, edit the /NFS/nfs-main-server.sh AND /NTP/ntm-main-server.sh and replace '10.42.0.0/24' with your network address.

Usage of the setup.sh script:
On main server:
  sudo ./setup.sh -m 
On backup server:
  sudo ./setup.sh -b

The current cron file is set so that the server is backed up every 12h, go ahead and change that to your liking BEFORE running the script by editing the Backups/cron-config.txt file.

Nothing else will work.

# Quick Tour
- The setup script installs the different requirements
- Prompts for the RAID1 and monitoring setup

*The two points above need to run on both main and backup server*

Then if the user is on the main server:
- The script creates a project folder to store the backup script
- Runs the backup script
- Runs the ftp setup for the main server
- Runs the nfs setup for the main server
- Runs the ntp setup for the main server
- Adds the backups to the crontab file

Or if the user is on the backup server:
- Runs the ftp setup for the backup server
- Runs the nfs setup for the backup server
- Runs the ntp setup for the backup server

# TODO:
## Global
- [ ] Add easy user configuration

## Setup script
- [X] Run requirements script
- [X] Ask what server user is on (main or backup)
- [X] Run raid1 setup
- [X] (optionnal) run raid1 status check
- [X] Run monitoring script

If user is on main server:
- [X] Run backup script
- [X] Add crontab line to crontab for backups
- [X] Run ftp main server script
- [X] Run nfs main server script
- [X] Run ntp main server script

If user is on backup server:
- [X] Run ftp backup server script
- [X] Run nfs client server script
- [X] Run ntp client server script

