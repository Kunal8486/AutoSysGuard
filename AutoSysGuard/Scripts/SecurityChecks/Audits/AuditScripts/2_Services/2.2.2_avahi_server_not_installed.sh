# 2.2.2 Ensure Avahi Server is not installed (Automated)
#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Audit: Check if avahi-daemon is installed
echo "Checking if avahi-daemon is installed..."
avahi_status=$(dpkg-query -W -f='${binary:Package}\t${Status}\n' | grep -w avahi-daemon)

if [ -z "$avahi_status" ]; then
    echo "Audit passed: avahi-daemon is not installed."
else
    echo "Audit failed: avahi-daemon is installed."
    echo "$avahi_status"
    echo "Would you like to apply remediation? (y/n)"
    read -r remediation_choice
    if [[ "$remediation_choice" == "y" || "$remediation_choice" == "Y" ]]; then
        # Remediation: Stop the avahi-daemon service and remove it
        echo "Applying remediation..."
        sudo systemctl stop avahi-daemon.service
        sudo systemctl stop avahi-daemon.socket
        sudo apt purge -y avahi-daemon
        echo "avahi-daemon has been removed."
    else
        echo "Remediation skipped. avahi-daemon remains installed."
    fi
fi
