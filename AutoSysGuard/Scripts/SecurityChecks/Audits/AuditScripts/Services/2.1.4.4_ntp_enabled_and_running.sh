#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if ntp is installed
if ! command_exists ntp; then
    echo "ntp is not installed. Would you like to install it? (y/n)"
    read -r install_choice
    if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
        sudo apt update && sudo apt install ntp -y
        echo "ntp has been installed."
    else
        echo "ntp is not installed. Exiting..."
        exit 1
    fi
fi

# Audit: Check if ntp is enabled
is_enabled=$(systemctl is-enabled ntp.service 2>/dev/null)
is_active=$(systemctl is-active ntp.service 2>/dev/null)

# Check if systemd-timesyncd is in use
if systemctl is-active --quiet systemd-timesyncd; then
    echo "systemd-timesyncd is active and providing time synchronization. You may not need ntp."
    echo "Would you like to remove ntp? (y/n)"
    read -r remove_choice
    if [[ "$remove_choice" == "y" || "$remove_choice" == "Y" ]]; then
        sudo apt purge ntp -y
        echo "ntp has been removed."
    else
        echo "ntp remains installed on the system."
    fi
    exit 0
fi

# Display audit results
if [[ "$is_enabled" == "enabled" || "$is_enabled" == "alias" ]] && [[ "$is_active" == "active" ]]; then
    echo "Audit passed: ntp service is enabled and running."
else
    echo "Audit failed: ntp service is either not enabled or not running."
    echo "ntp status: enabled=$is_enabled, active=$is_active"
    echo "Would you like to apply remediation? (y/n)"
    read -r remediation_choice
    if [[ "$remediation_choice" == "y" || "$remediation_choice" == "Y" ]]; then
        # Remediation: unmask, enable and start ntp
        echo "Applying remediation..."
        sudo systemctl unmask ntp.service
        sudo systemctl --now enable ntp.service || echo "Failed to enable ntp.service. It might be linked or replaced by another service."
        echo "Remediation completed."
    else
        echo "Remediation skipped."
    fi
fi

# Ask if user wants to remove ntp if another time sync service is in use
echo "If you are using another time synchronization service, would you like to remove ntp? (y/n)"
read -r remove_choice
if [[ "$remove_choice" == "y" || "$remove_choice" == "Y" ]]; then
    sudo apt purge ntp -y
    echo "ntp has been removed."
else
    echo "ntp remains installed on the system."
fi
