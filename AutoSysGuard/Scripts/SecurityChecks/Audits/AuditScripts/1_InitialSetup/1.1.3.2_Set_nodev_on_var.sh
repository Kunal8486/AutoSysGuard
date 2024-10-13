#!/bin/bash

# Audit section
echo "Auditing /var mount options for nodev..."
if findmnt -kn /var | grep -q 'nodev'; then
    echo "/var is correctly mounted with the nodev option."
else
    echo "/var is NOT mounted with the nodev option."

    # Prompt for remediation
    read -p "Do you want to apply remediation? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        # Remediation section
        echo "Editing /etc/fstab to add nodev option..."

        # Backup current fstab
        cp /etc/fstab /etc/fstab.bak

        # Check if /var entry exists in fstab
        if grep -q '/var' /etc/fstab; then
            # Add nodev option to the /var partition
            sed -i '/\/var/ s/\(.*\)\(defaults[^,]*\)\(.*\)/\1\2,nodev\3/' /etc/fstab
        else
            echo "Error: No entry found for /var in /etc/fstab."
            exit 1
        fi
        
        # Verify the fstab syntax
        if ! mount -o remount /var; then
            echo "Error: Unable to remount /var. Please check your /etc/fstab for syntax errors."
            exit 1
        fi

        echo "/var has been remounted with the nodev option."
    else
        echo "Remediation will not be applied."
    fi
fi
