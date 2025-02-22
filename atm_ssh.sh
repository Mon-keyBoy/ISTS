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
systemctl restart ssh
systemctl enable ssh
systemctl restart sshd
systemctl enable sshd

# Make SSH and system file backups
cp -r /etc/ssh "$BACKUP_PATH/ssh"
cp /etc/passwd /etc/shadow /etc/group /etc/gshadow "$BACKUP_PATH/"
cp /etc/sudoers "$BACKUP_PATH/"
cp -r /etc/sudoers.d "$BACKUP_PATH/sudoers.d"
cp -r /etc/pam.d "$BACKUP_PATH/pam.d"
cp -r /etc/netplan "$BACKUP_PATH/netplan"
cp /etc/hosts /etc/hostname /etc/resolv.conf "$BACKUP_PATH/"

# Flush and disable legacy iptables
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -t raw -F
iptables -X

iptables-legacy -F
iptables-legacy -t nat -F
iptables-legacy -t mangle -F
iptables-legacy -t raw -F
iptables-legacy -X

iptables-nft -F
iptables-nft -t nat -F
iptables-nft -t mangle -F
iptables-nft -t raw -F
iptables-nft -X

# systemctl stop iptables iptables-legacy iptables-persistent
# systemctl disable iptables iptables-legacy iptables-persistent

# # Blacklist legacy iptables kernel modules
# BLACKLIST_FILE="/etc/modprobe.d/blacklist.conf"
# if [ ! -f "$BLACKLIST_FILE" ]; then
#     echo "Creating blacklist configuration file at $BLACKLIST_FILE"
#     touch "$BLACKLIST_FILE"
# fi

# cat >> "$BLACKLIST_FILE" <<EOF
# blacklist ip_tables
# blacklist iptable_nat
# blacklist ip6_tables
# blacklist iptable_mangle
# blacklist iptable_raw
# EOF

# depmod -a
# apt install -y initramfs-tools
# update-initramfs -u

# # Remove persistent iptables rules
# rm -f /etc/iptables/rules.v4 /etc/iptables/rules.v6

# Set nftables as the default firewall
update-alternatives --set iptables /usr/sbin/iptables-nft
update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
update-alternatives --set arptables /usr/sbin/arptables-nft
update-alternatives --set ebtables /usr/sbin/ebtables-nft

# Flush existing nftables rules
nft flush ruleset

# # Disable firewalld and ufw
# systemctl disable --now firewalld ufw

# Set up nftables
nft add table ip filter

# Input chain
nft add chain ip filter input { type filter hook input priority 0 \; }
nft add rule ip filter input iif lo accept                             # Allow loopback
nft add rule ip filter input ct state established,related log prefix "nftables: " accept
nft add rule ip filter input tcp dport 22 accept                       # Allow SSH
nft add rule ip filter input icmp type echo-request accept             # Allow ping
nft add rule ip filter input drop                                      # Drop everything else

# Output chain
nft add chain ip filter output { type filter hook output priority 0 \; }
nft add rule ip filter output ct state established,related log prefix "nftables: " accept
nft add rule ip filter output udp dport 53 accept                      # Allow DNS
nft add rule ip filter output tcp dport 80 accept                      # Allow HTTP
nft add rule ip filter output tcp dport 443 accept                     # Allow HTTPS
nft add rule ip filter output drop                                     # Drop everything else

# Save nftables rules and make them immutable
nft list ruleset > /etc/nftables.conf
cp /etc/nftables.conf "$BACKUP_PATH/nftables_rules.bak"
chattr +i /etc/nftables.conf
systemctl start nftables
systemctl enable nftables

# # Require signed kernel modules
# sed -i 's/\(vmlinuz.*\)/\1 module.sig_enforce=1 module.sig_unenforce=0/' /boot/grub/grub.cfg

# #disable cron
# systemctl stop cron
# systemctl disable cron
# chattr +i /etc/crontab
# chattr +i /etc/cron.d
# chattr +i /etc/cron.daily
# chattr +i /etc/cron.hourly
# chattr +i /etc/cron.monthly
# chattr +i /etc/cron.weekly

# #get rif of cups
# systemctl stop cups
# systemctl disable cups
# systemctl stop cups.service cups.socket cups.path
# systemctl disable cups.service cups.socket cups.path
# apt remove --purge -y cups

# Script completion message
echo "."
echo "."
echo "."
echo "Script Complete, please reboot!"
