#!/bin/bash

# Function to check the nosuid option on /var
check_nosuid() {
    if findmnt -kn /var | grep -v 'nosuid' > /dev/null; then
        return 1  # nosuid is not set
    else
        return 0  # nosuid is set
    fi
}

# Function to apply remediation
apply_remediation() {
    # Check if /var partition exists
    if mountpoint -q /var; then
        echo "Updating /etc/fstab to add nosuid option for /var..."
        
        # Create a backup of the original fstab
        cp /etc/fstab /etc/fstab.bak
        
        # Add nosuid to the /var entry in /etc/fstab
        sed -i.bak '/\/var/ s/\(defaults[^\n]*\)/\1,nosuid,nodev,relatime/' /etc/fstab
        
        echo "Remounting /var with the new options..."
        mount -o remount /var
        
        echo "/var has been remounted with the nosuid option."
    else
        echo "/var partition does not exist. No remediation applied."
    fi
}

# Start of the script
echo "Checking if the nosuid option is set for /var..."

if check_nosuid; then
    echo "The nosuid option is already set for /var."
else
    echo "The nosuid option is NOT set for /var."
    read -p "Do you want to apply the remediation? (y/n): " response

    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes have been made."
    fi
fi
