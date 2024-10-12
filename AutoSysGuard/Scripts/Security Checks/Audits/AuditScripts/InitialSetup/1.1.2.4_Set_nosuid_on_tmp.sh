#!/bin/bash

# Function to check the nosuid option for /tmp
check_nosuid() {
    if findmnt -kn /tmp | grep -q nosuid; then
        echo "Audit passed: The nosuid option is set for /tmp."
        return 0
    else
        echo "Audit failed: The nosuid option is NOT set for /tmp."
        return 1
    fi
}

# Function to apply remediation for nosuid option
apply_nosuid_remediation() {
    echo "Applying remediation..."
    # Backup the /etc/fstab file
    cp /etc/fstab /etc/fstab.bak
    echo "Backup of /etc/fstab created as /etc/fstab.bak."

    # Update /etc/fstab for /tmp
    # Extract existing line for /tmp
    existing_line=$(grep '/tmp' /etc/fstab)
    if [[ -n "$existing_line" ]]; then
        # Modify the line to include nosuid option
        modified_line=$(echo "$existing_line" | sed 's/defaults/defaults,nosuid/')
        # Replace the old line with the new line
        sed -i "s|$existing_line|$modified_line|" /etc/fstab
        echo "Updated /etc/fstab for /tmp to include nosuid option."
    else
        echo "Error: /tmp not found in /etc/fstab."
        return 1
    fi

    # Remount /tmp with new options
    mount -o remount /tmp
    echo "/tmp has been remounted with the nosuid option."
}

# Main script logic
check_nosuid
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply the remediation for nosuid option? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        apply_nosuid_remediation
    else
        echo "Remediation not applied."
    fi
fi
