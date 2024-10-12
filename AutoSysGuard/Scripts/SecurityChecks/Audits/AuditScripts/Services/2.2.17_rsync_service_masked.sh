#!/bin/bash

# Function to check if rsync is installed
check_rsync_installed() {
    dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' rsync | grep -P '^rsync\s+unknown\s+ok\s+not-installed' > /dev/null
    return $?
}

# Function to check if rsync is inactive and masked
check_rsync_status() {
    local active_status=$(systemctl is-active rsync 2>/dev/null)
    local enabled_status=$(systemctl is-enabled rsync 2>/dev/null)

    if [[ "$active_status" == "inactive" && "$enabled_status" == "masked" ]]; then
        return 0 # rsync is inactive and masked
    fi
    return 1 # rsync is either active or not masked
}

# Function to apply remediation by removing rsync
apply_remediation_remove() {
    echo "Removing rsync..."
    sudo apt purge rsync -y
    if [[ $? -eq 0 ]]; then
        echo "rsync has been successfully removed."
    else
        echo "Failed to remove rsync. Please check your permissions or package status."
    fi
}

# Function to apply remediation by stopping and masking rsync
apply_remediation_mask() {
    echo "Stopping and masking rsync service..."
    sudo systemctl stop rsync
    sudo systemctl mask rsync
    if [[ $? -eq 0 ]]; then
        echo "rsync service has been successfully stopped and masked."
    else
        echo "Failed to stop and mask rsync. Please check your permissions or service status."
    fi
}

# Main script execution
echo "Checking rsync installation and service status..."

if check_rsync_installed; then
    echo "rsync is not installed."
else
    echo "rsync is currently installed."

    if check_rsync_status; then
        echo "rsync is inactive and masked."
        exit 0 # No action needed as the requirement is already met
    else
        echo "rsync is currently active or not masked."
        read -p "Do you want to stop and mask the rsync service? (y/n): " user_response
        if [[ "$user_response" =~ ^[Yy]$ ]]; then
            apply_remediation_mask
        else
            echo "No changes made to the rsync service."
        fi
    fi
fi

# If rsync was installed, ask user for confirmation to remove it
if ! check_rsync_installed; then
    read -p "Do you want to remove the installed rsync package? (y/n): " remove_response
    if [[ "$remove_response" =~ ^[Yy]$ ]]; then
        apply_remediation_remove
    else
        echo "No changes made to the rsync package."
    fi
fi
