#!/bin/bash

# Function to check the nosuid option
check_nosuid() {
    echo "Checking nosuid option for /var/log/audit..."
    if findmnt -kn /var/log/audit | grep -qv 'nosuid'; then
        echo "The nosuid option is NOT set for /var/log/audit."
        return 1  # Return 1 if nosuid is not set
    else
        echo "The nosuid option is set for /var/log/audit."
        return 0  # Return 0 if nosuid is set
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Check if the /var/log/audit partition exists
    if mount | grep -q '/var/log/audit'; then
        echo "Editing /etc/fstab to add nosuid option..."
        
        # Create a backup of fstab
        cp /etc/fstab /etc/fstab.bak
        
        # Check if the entry for /var/log/audit exists and modify it
        if grep -q '/var/log/audit' /etc/fstab; then
            sed -i 's/\(\/var\/log\/audit.*\)\(defaults\)/\1\2,nosuid/' /etc/fstab
        else
            # Add entry if it doesn't exist
            echo "<device> /var/log/audit <fstype> defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
        fi

        # Remount the /var/log/audit
        mount -o remount /var/log/audit
        echo "Remounted /var/log/audit with nosuid option."
    else
        echo "The /var/log/audit partition does not exist."
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
