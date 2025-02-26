#!/bin/bash

# Ensure the script runs as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (use sudo)."
  exit 1
fi

# Prompt user for the backup directory
read -rp "Enter the backup directory path: " BACKUP_DIR

# Create a hidden directory for backups
mkdir -p "$BACKUP_PATH"

mkdir -p "$BACKUP_DIR/config"
mkdir -p "$BACKUP_DIR/databases"
mkdir -p "$BACKUP_DIR/logs"
mkdir -p "$BACKUP_DIR/system"

cp -r /etc/mysql/ "$BACKUP_DIR/config/"
cp -r /var/log/mysql/ "$BACKUP_DIR/logs/"
mysqldump --all-databases --single-transaction --quick --lock-tables=false > "$BACKUP_DIR/databases/mysql_all_databases.sql"
# mysqldump -u root -p --all-databases > "$BACKUP_DIR"/databases/double/backup.sql



systemctl stop cron
systemctl disable cron

# Lock cron-related files to prevent changes
chattr +i /etc/crontab
chattr +i /etc/cron.d
chattr +i /etc/cron.daily
chattr +i /etc/cron.hourly
chattr +i /etc/cron.monthly
chattr +i /etc/cron.weekly

systemctl stop cups
systemctl disable cups

# Also stop and disable related cups services
systemctl stop cups.service cups.socket cups.path
systemctl disable cups.service cups.socket cups.path

# Remove cups and its dependencies
apt remove --purge -y cups 
