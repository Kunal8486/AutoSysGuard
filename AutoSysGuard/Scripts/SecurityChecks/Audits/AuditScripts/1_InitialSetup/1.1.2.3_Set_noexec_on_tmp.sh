#!/bin/bash

# Function to check the noexec option for /tmp
check_noexec() {
    if findmnt -kn /tmp | grep -q noexec; then
        echo "Audit passed: The noexec option is set for /tmp."
        return 0
    else
        echo "Audit failed: The noexec option is NOT set for /tmp."
        return 1
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    # Backup the /etc/fstab file
    cp /etc/fstab /etc/fstab.bak
    echo "Backup of /etc/fstab created as /etc/fstab.bak."

    # Update /etc/fstab for /tmp
    # Extract existing line for /tmp
    existing_line=$(grep '/tmp' /etc/fstab)
    if [[ -n "$existing_line" ]]; then
        # Modify the line to include noexec option
        modified_line=$(echo "$existing_line" | sed 's/defaults/defaults,noexec/')
        # Replace the old line with the new line
        sed -i "s|$existing_line|$modified_line|" /etc/fstab
        echo "Updated /etc/fstab for /tmp to include noexec option."
    else
        echo "Error: /tmp not found in /etc/fstab."
        return 1
    fi

    # Remount /tmp with new options
    mount -o remount /tmp
    echo "/tmp has been remounted with the noexec option."
}

# Main script logic
check_noexec
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply the remediation? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        apply_remediation
    else
        echo "Remediation not applied."
    fi
fi
