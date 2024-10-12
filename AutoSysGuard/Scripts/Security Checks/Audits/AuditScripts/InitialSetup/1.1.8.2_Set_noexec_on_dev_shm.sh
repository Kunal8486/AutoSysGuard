#!/bin/bash

# Function to check the noexec option
check_noexec() {
    echo "Checking noexec option for /dev/shm..."
    if findmnt -kn /dev/shm | grep -qv 'noexec'; then
        echo "The noexec option is NOT set for /dev/shm."
        return 1  # Return 1 if noexec is not set
    else
        echo "The noexec option is set for /dev/shm."
        return 0  # Return 0 if noexec is set
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    echo "Editing /etc/fstab to add noexec option..."

    # Create a backup of fstab
    cp /etc/fstab /etc/fstab.bak

    # Check if the entry for /dev/shm exists and modify it
    if grep -q '/dev/shm' /etc/fstab; then
        sed -i 's/\(\/dev\/shm.*\)\(defaults\)/\1\2,noexec/' /etc/fstab
    else
        # Add entry if it doesn't exist
        echo "tmpfs /dev/shm tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
    fi

    # Remount the /dev/shm partition
    mount -o remount /dev/shm
    echo "Remounted /dev/shm with noexec option."
}

# Main script execution
if check_noexec; then
    echo "No remediation needed."
else
    read -p "Would you like to apply remediation? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        apply_remediation
    else
        echo "Remediation not applied."
    fi
fi
