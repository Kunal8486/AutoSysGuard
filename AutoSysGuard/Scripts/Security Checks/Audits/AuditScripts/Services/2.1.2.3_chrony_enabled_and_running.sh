#!/bin/bash

# Function to check the status of the chrony service
check_chrony_status() {
    local enabled_status
    local active_status

    enabled_status=$(systemctl is-enabled chrony.service 2>/dev/null)
    active_status=$(systemctl is-active chrony.service 2>/dev/null)

    echo "Chrony Service Audit:"
    echo "Enabled Status: $enabled_status"
    echo "Active Status: $active_status"

    # Return status
    if [[ "$enabled_status" == "enabled" && "$active_status" == "active" ]]; then
        return 0  # Chrony is enabled and active
    else
        return 1  # Chrony is not properly configured
    fi
}

# Function to apply remediation
apply_remediation() {
    read -p "Do you want to apply remediation for chrony? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Unmasking chrony.service..."
        systemctl unmask chrony.service

        echo "Enabling and starting chrony.service..."
        systemctl --now enable chrony.service

        echo "Chrony has been enabled and started."
    elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
        echo "No changes were made."
    else
        echo "Invalid choice. Please enter 'y' or 'n'."
        apply_remediation  # Retry on invalid input
    fi
}

# Main script execution
if systemctl list-unit-files | grep -q chrony.service; then
    echo "Chrony service found."
    if check_chrony_status; then
        echo "Chrony is already enabled and active."
    else
        echo "Chrony is not properly configured."
        apply_remediation
    fi
else
    echo "Chrony service is not installed on this system."
fi

