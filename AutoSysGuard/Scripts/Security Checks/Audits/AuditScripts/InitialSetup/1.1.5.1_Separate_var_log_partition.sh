#!/bin/bash

# Function to check if /var/log is mounted
check_var_log() {
    echo "Checking if /var/log is mounted..."
    if findmnt -kn /var/log > /dev/null; then
        echo "/var/log is mounted."
        return 0  # Mounted
    else
        echo "/var/log is NOT mounted."
        return 1  # Not mounted
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Check if the user wants to proceed with remediation
    read -p "Do you want to create a new partition for /var/log? (y/n): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            # Prompt for the new partition details
            read -p "Enter the device name for the new partition (e.g., /dev/sdb1): " device
            read -p "Enter the filesystem type (e.g., ext4): " fstype
            
            # Create a filesystem on the new partition
            echo "Creating filesystem on $device..."
            mkfs -t "$fstype" "$device"
            
            # Create the mount point if it doesn't exist
            mkdir -p /var/log
            
            # Update /etc/fstab
            echo "$device /var/log $fstype defaults 0 0" >> /etc/fstab
            echo "Updated /etc/fstab for /var/log."

            # Mount the new partition
            mount "$device" /var/log
            echo "/var/log has been mounted."
            ;;
        [nN][oO]|[nN])
            echo "No changes made."
            ;;
        *)
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
}

# Main script execution
check_var_log
if [ $? -eq 1 ]; then
    read -p "Do you want to apply remediation to create a new partition for /var/log? (y/n): " response
    case "$response" in
        [yY][eE][sS]|[yY])
            apply_remediation
            ;;
        [nN][oO]|[nN])
            echo "No changes made."
            ;;
        *)
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
else
    echo "Audit completed. No remediation needed."
fi
