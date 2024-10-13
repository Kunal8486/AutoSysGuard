#!/bin/bash

# Function to check if /var/tmp is mounted
check_var_tmp() {
    if findmnt -kn /var/tmp > /dev/null; then
        return 0  # /var/tmp is mounted
    else
        return 1  # /var/tmp is not mounted
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "To apply remediation, please follow these steps:"
    
    # Prompt for partition information
    read -p "Enter the device name for the new partition (e.g., /dev/sdX): " device
    read -p "Enter the filesystem type (e.g., ext4): " fstype
    read -p "Enter the mount point (e.g., /var/tmp): " mountpoint

    # Create the partition (note: this will delete all data on the device)
    echo "Creating filesystem on $device..."
    mkfs.$fstype $device

    # Backup the current fstab
    echo "Backing up /etc/fstab to /etc/fstab.bak..."
    cp /etc/fstab /etc/fstab.bak

    # Add the new partition to /etc/fstab
    echo "Updating /etc/fstab..."
    echo "$device $mountpoint $fstype defaults 0 0" >> /etc/fstab

    # Create the mount point if it doesn't exist
    mkdir -p $mountpoint

    # Mount the new partition
    mount $mountpoint
    echo "$mountpoint has been successfully mounted."
}

# Start of the script
echo "Checking if /var/tmp is mounted..."

if check_var_tmp; then
    echo "/var/tmp is already mounted."
else
    echo "/var/tmp is NOT mounted."
    read -p "Do you want to apply remediation? (y/n): " response

    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes have been made."
    fi
fi
