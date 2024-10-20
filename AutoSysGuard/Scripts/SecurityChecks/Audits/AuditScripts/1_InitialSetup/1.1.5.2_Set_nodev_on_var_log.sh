#!/bin/bash

# Function to check if nodev option is set for /var/log
check_nodev() {
    echo "Checking if the 'nodev' option is set for /var/log..."
    if findmnt -kn /var/log | grep -q 'nodev'; then
        echo "'nodev' option is set for /var/log."
        return 0  # No action needed
    else
        echo "'nodev' option is NOT set for /var/log."
        return 1  # Action needed
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Check if /var/log is mounted
    if mount | grep -q '/var/log'; then
        echo "/var/log partition exists."
        
        # Edit /etc/fstab to add nodev if not already present
        if grep -q '/var/log' /etc/fstab; then
            # Use sed to add nodev to the mounting options
            sed -i.bak "s/\(\/var\/log.*\)\(defaults.*\)/\1\2,nodev/" /etc/fstab
            echo "Updated /etc/fstab with 'nodev' option."
        else
            echo "No entry for /var/log found in /etc/fstab."
            echo "<device> /var/log <fstype> defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
            echo "Added entry for /var/log in /etc/fstab."
        fi

        # Remount /var/log with the new options
        mount -o remount /var/log
        echo "/var/log remounted with 'nodev' option."
    else
        echo "/var/log partition does not exist."
    fi
}

# Main script execution
check_nodev
if [ $? -eq 1 ]; then
    read -p "Do you want to apply remediation to set the 'nodev' option for /var/log? (y/n): " response
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
