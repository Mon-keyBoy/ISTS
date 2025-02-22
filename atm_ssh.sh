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

# Script completion message
echo "."
echo "."
echo "."
echo "Script Complete, please reboot!"
