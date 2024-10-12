#!/bin/bash

# Function to check the nosuid option
check_nosuid() {
    echo "Checking nosuid option for /home..."
    if findmnt -kn /home | grep -qv 'nosuid'; then
        echo "The nosuid option is NOT set for /home."
        return 1  # Return 1 if nosuid is not set
    else
        echo "The nosuid option is set for /home."
        return 0  # Return 0 if nosuid is set
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Check if the /home partition exists
    if mount | grep -q '/home'; then
        echo "Editing /etc/fstab to add nosuid option..."

        # Create a backup of fstab
        cp /etc/fstab /etc/fstab.bak
        
        # Check if the entry for /home exists and modify it
        if grep -q '/home' /etc/fstab; then
            sed -i 's/\(\/home.*\)\(defaults\)/\1\2,nosuid/' /etc/fstab
        else
            # Add entry if it doesn't exist
            echo "<device> /home <fstype> defaults,rw,nosuid,nodev,relatime 0 0" >> /etc/fstab
        fi

        # Remount the /home partition
        mount -o remount /home
        echo "Remounted /home with nosuid option."
    else
        echo "The /home partition does not exist."
    fi
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
