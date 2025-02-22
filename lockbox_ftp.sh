#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# Set backup path
BACKUP_PATH="/var/log/SYSLOG"

# Create a hidden directory for backups
mkdir -p "$BACKUP_PATH"

# Remove SSH completely
systemctl stop ssh
systemctl disable ssh
apt remove --purge -y openssh-server openssh-client
rm -rf /etc/ssh
echo "SSH removed successfully."

# enable what is probably the service
systemctl start vsftpd
systemctl enable vsftpd

# Make SSH and system file backups
mkdir -p "$BACKUP_PATH/ftp"
find /etc -iname '*ftp*' -exec cp --parents {} "$BACKUP_PATH/ftp" \;
cp -r /srv/ftp "$BACKUP_DIR/"
cp -r /home/ftp* "$BACKUP_DIR/"
cp -r /var/ftp "$BACKUP_DIR/"



# Require signed kernel modules
sed -i 's/\(vmlinuz.*\)/\1 module.sig_enforce=1 module.sig_unenforce=0/' /boot/grub/grub.cfg

#disable cron
systemctl stop cron
systemctl disable cron
chattr +i /etc/crontab
chattr +i /etc/cron.d
chattr +i /etc/cron.daily
chattr +i /etc/cron.hourly
chattr +i /etc/cron.monthly
chattr +i /etc/cron.weekly

#get rif of cups
systemctl stop cups
systemctl disable cups
systemctl stop cups.service cups.socket cups.path
systemctl disable cups.service cups.socket cups.path
apt remove --purge -y cups
Script completion message


echo "."
echo "."
echo "."
echo "Script Complete, please reboot!"
