#!/bin/bash

# Function to check the nodev option on /var/tmp
check_nodev() {
    echo "Checking if the 'nodev' option is set for /var/tmp..."
    if findmnt -kn /var/tmp | grep -q 'nodev'; then
        echo "The 'nodev' option is set correctly for /var/tmp."
        return 0  # nodev is set
    else
        echo "The 'nodev' option is NOT set for /var/tmp."
        return 1  # nodev is not set
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    fstab_entry="<device> /var/tmp <fstype> defaults,rw,nosuid,nodev,noexec,relatime 0 0"
    
    # Check if the /var/tmp entry exists in /etc/fstab
    if grep -q "/var/tmp" /etc/fstab; then
        echo "Updating the existing /etc/fstab entry for /var/tmp..."
        # Update the existing entry (modify this based on your system)
        sed -i.bak "/\/var\/tmp/c\\$fstab_entry" /etc/fstab
    else
        echo "Adding new entry to /etc/fstab for /var/tmp..."
        echo "$fstab_entry" >> /etc/fstab
    fi

    # Reload systemd
    echo "Reloading systemd daemon..."
    systemctl daemon-reload

    # Remount /var/tmp if it is already mounted
    if mountpoint -q /var/tmp; then
        mount -o remount /var/tmp
        echo "/var/tmp has been remounted with the configured options."
    else
        echo "/var/tmp is not currently mounted. Please mount it manually or check the mount point."
    fi
}

# Main script execution
check_nodev
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation for /var/tmp? (y/n): " user_input
    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes made. Exiting..."
    fi
else
    echo "No remediation needed."
fi
