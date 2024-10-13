#!/bin/bash

# Function to check if /var/log/audit is mounted
check_audit_mount() {
    mount_info=$(findmnt -kn /var/log/audit)
    
    if [ -z "$mount_info" ]; then
        echo "/var/log/audit is not mounted."
        return 1
    else
        echo "/var/log/audit is mounted."
        echo "$mount_info"
        return 0
    fi
}

# Function for remediation
apply_remediation() {
    read -p "Enter the disk (e.g., /dev/sdb) to create a new partition: " disk
    echo "Proceeding to create a new partition for /var/log/audit on $disk."

    # Check if the specified disk exists
    if [ ! -b "$disk" ]; then
        echo "Error: $disk does not exist. Please check your device and try again."
        exit 1
    fi

    # Example commands for creating a new partition (modify as needed)
    # NOTE: Ensure you run the following commands as root or using sudo

    # Create a new partition (adjust partition size as needed)
    echo "Creating a new partition on $disk..."
    (echo n; echo p; echo ; echo ; echo +1G; echo w) | fdisk "$disk"

    # Format the new partition (replace /dev/sdb1 with the correct partition name)
    echo "Formatting the new partition..."
    mkfs.ext4 "${disk}1"  # This assumes the new partition will be /dev/sdb1

    # Create the mount point if it does not exist
    mkdir -p /var/log/audit

    # Add entry to /etc/fstab
    echo "${disk}1 /var/log/audit ext4 defaults 0 2" >> /etc/fstab

    # Mount all filesystems
    mount -a

    echo "/var/log/audit has been created and mounted successfully."
}

# Main script execution
check_audit_mount
if [ $? -ne 0 ]; then
    read -p "Would you like to apply remediation? (y/n): " user_choice
    if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
        apply_remediation
    else
        echo "Remediation not applied."
    fi
fi
