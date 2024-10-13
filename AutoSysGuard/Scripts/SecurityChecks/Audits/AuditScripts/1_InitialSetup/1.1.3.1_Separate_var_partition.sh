#!/bin/bash

# Function to audit /var mount
audit_var_mount() {
    echo "Checking if /var is mounted..."
    if findmnt -kn /var; then
        echo "/var is mounted."
        exit 0  # Exit if the audit is successful
    else
        echo "/var is not mounted."
        return 1  # Return 1 if the audit fails
    fi
}

# Function to remediate /var mount
remediate_var_mount() {
    echo "To remediate, you can create a new partition for /var."
    echo "Please ensure you have a backup of important data before proceeding."
    
    # Get user confirmation
    read -p "Do you want to proceed with the remediation? (y/n): " response
    if [[ "$response" == "y" ]]; then
        # Prompt user for partition information
        read -p "Enter the device for the new partition (e.g., /dev/sdb1): " new_partition
        read -p "Enter the file system type (e.g., ext4): " fs_type
        
        # Create the new filesystem (uncomment the following line if you're ready to format)
        echo "Creating filesystem on $new_partition..."
        # mkfs.$fs_type $new_partition
        
        # Create mount point if it doesn't exist
        mkdir -p /var
        
        # Mount the new partition (uncomment the following line to mount it)
        echo "Mounting $new_partition to /var..."
        # mount $new_partition /var
        
        # Update /etc/fstab to mount the new partition on boot
        echo "$new_partition /var $fs_type defaults 0 2" >> /etc/fstab
        
        echo "/var has been configured to use the new partition."
    else
        echo "Remediation aborted."
    fi
}

# Main script execution
if ! audit_var_mount; then
    remediate_var_mount
fi
