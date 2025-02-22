#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# Set backup path
BACKUP_PATH="/var/log/SYSLOG"

# Create a hidden directory for backups
mkdir -p "$BACKUP_PATH"

# Secure SSHD configuration
sed -i 's/^#\?UsePAM yes/UsePAM no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitEmptyPasswords .*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
chattr +i "/etc/ssh/sshd_config"

# Restart and enable SSH services
systemctl enable ssh
systemctl enable sshd

# Make SSH and system file backups
cp -r /etc/ssh "$BACKUP_PATH/ssh"
cp /etc/passwd /etc/shadow /etc/group /etc/gshadow "$BACKUP_PATH/"
cp /etc/sudoers "$BACKUP_PATH/"
cp -r /etc/sudoers.d "$BACKUP_PATH/sudoers.d"
cp -r /etc/pam.d "$BACKUP_PATH/pam.d"
cp -r /etc/netplan "$BACKUP_PATH/netplan"
cp /etc/hosts /etc/hostname /etc/resolv.conf "$BACKUP_PATH/"


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
