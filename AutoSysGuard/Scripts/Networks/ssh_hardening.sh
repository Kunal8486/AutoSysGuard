#!/bin/bash

# SSH Hardening Script
SSH_LOG="/var/log/autosysguard/ssh_hardening.log"
mkdir -p /var/log/autosysguard

echo "SSH Hardening - $(date)" >> "$SSH_LOG"

# Disable root login
echo "Disabling root login..." >> "$SSH_LOG"
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication
echo "Disabling password authentication..." >> "$SSH_LOG"
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH service
echo "Restarting SSH service..." >> "$SSH_LOG"
sudo systemctl restart ssh

echo "SSH hardening completed." >> "$SSH_LOG"
echo "-----------------------" >> "$SSH_LOG"
