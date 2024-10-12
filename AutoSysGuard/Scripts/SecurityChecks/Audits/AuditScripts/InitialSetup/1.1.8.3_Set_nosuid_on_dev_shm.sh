#!/bin/bash

# Function to check the nosuid option
check_nosuid() {
    echo "Checking nosuid option for /dev/shm..."
    if findmnt -kn /dev/shm | grep -qv 'nosuid'; then
        echo "The nosuid option is NOT set for /dev/shm."
        return 1  # Return 1 if nosuid is not set
    else
        echo "The nosuid option is set for /dev/shm."
        return 0  # Return 0 if nosuid is set
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    echo "Editing /etc/fstab to add nosuid option..."

    # Create a backup of fstab
    cp /etc/fstab /etc/fstab.bak

    # Check if the entry for /dev/shm exists and modify it
    if grep -q '/dev/shm' /etc/fstab; then
        sed -i 's/\(\/dev\/shm.*\)\(defaults\)/\1\2,nosuid/' /etc/fstab
    else
        # Add entry if it doesn't exist
        echo "tmpfs /dev/shm tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
    fi

    # Remount the /dev/shm partition
    mount -o remount /dev/shm
    echo "Remounted /dev/shm with nosuid option."
}

# Main script execution
if check_nosuid; then
    echo "No remediation needed."
else
    read -p "Would you like to apply remediation? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        apply_remediation
    else
        echo "Remediation not applied."
    fi
fi
