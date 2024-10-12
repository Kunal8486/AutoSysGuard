# 2.1.4.1 Ensure ntp access control is configured (Automated)

#!/bin/bash

# Check if ntp is installed
if dpkg -l | grep -q "ntp"; then
    echo "NTP is installed on the system."
else
    echo "NTP is not installed. Skipping this audit."
    exit 0
fi

# Check if chrony or systemd-timesyncd is being used
if systemctl is-active --quiet chronyd || systemctl is-active --quiet systemd-timesyncd; then
    echo "Another time synchronization service (chrony or systemd-timesyncd) is in use."
    echo "It is recommended to remove ntp. Skipping this audit."
    read -p "Would you like to remove ntp? (y/n): " response
    if [[ "$response" == "y" ]]; then
        sudo apt purge ntp -y
        echo "ntp has been removed."
    else
        echo "ntp removal skipped."
    fi
    exit 0
fi

# Audit check 1: Check if ntpd is running as user ntp
ps_check=$(ps -ef | awk '(/[n]tpd/ && $1!="ntp") { print $1 }')

if [ -z "$ps_check" ]; then
    echo "Audit passed: ntpd is running as user ntp."
else
    echo "Audit failed: ntpd is not running as user ntp."
    read -p "Would you like to apply remediation? (y/n): " response
    if [[ "$response" == "y" ]]; then
        # Apply remediation by setting RUNASUSER to ntp
        sudo sed -i 's/^RUNASUSER=.*/RUNASUSER=ntp/' /usr/lib/ntp/ntp-systemd-wrapper
        echo "RUNASUSER set to ntp in /usr/lib/ntp/ntp-systemd-wrapper."
        # Restart ntp service
        sudo systemctl restart ntp.service
        echo "ntp service has been restarted."
    else
        echo "Remediation skipped."
    fi
fi

# Audit check 2: Verify RUNASUSER=ntp in ntp-systemd-wrapper
runasuser_check=$(grep -P -- '^\h*RUNASUSER=' /usr/lib/ntp/ntp-systemd-wrapper)

if [[ "$runasuser_check" == "RUNASUSER=ntp" ]]; then
    echo "Audit passed: RUNASUSER is set to ntp in /usr/lib/ntp/ntp-systemd-wrapper."
else
    echo "Audit failed: RUNASUSER is not set to ntp in /usr/lib/ntp/ntp-systemd-wrapper."
    read -p "Would you like to apply remediation? (y/n): " response
    if [[ "$response" == "y" ]]; then
        # Apply remediation by setting RUNASUSER to ntp
        sudo sed -i 's/^RUNASUSER=.*/RUNASUSER=ntp/' /usr/lib/ntp/ntp-systemd-wrapper
        echo "RUNASUSER set to ntp in /usr/lib/ntp/ntp-systemd-wrapper."
        # Restart ntp service
        sudo systemctl restart ntp.service
        echo "ntp service has been restarted."
    else
        echo "Remediation skipped."
    fi
fi
