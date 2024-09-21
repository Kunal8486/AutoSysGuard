#!/bin/bash

# Firewall Configuration Script
FIREWALL_LOG="/var/log/autosysguard/firewall.log"
mkdir -p /var/log/autosysguard

echo "Firewall Configuration - $(date)" >> "$FIREWALL_LOG"

# Check firewall status
echo "Current Firewall Status:" >> "$FIREWALL_LOG"
sudo ufw status verbose >> "$FIREWALL_LOG"

# Enable firewall
echo "Enabling Firewall..." >> "$FIREWALL_LOG"
sudo ufw enable >> "$FIREWALL_LOG"

# Allow SSH and HTTP traffic
echo "Allowing SSH and HTTP traffic..." >> "$FIREWALL_LOG"
sudo ufw allow ssh >> "$FIREWALL_LOG"
sudo ufw allow http >> "$FIREWALL_LOG"

# Deny all incoming connections except allowed ones
echo "Setting default deny policy for incoming connections..." >> "$FIREWALL_LOG"
sudo ufw default deny incoming >> "$FIREWALL_LOG"

echo "Firewall rules updated." >> "$FIREWALL_LOG"
echo "-----------------------" >> "$FIREWALL_LOG"
