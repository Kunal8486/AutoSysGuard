#!/bin/bash

# Function to check if noexec option is set for /var/log
check_noexec() {
    echo "Checking if the 'noexec' option is set for /var/log..."
    if findmnt -kn /var/log | grep -q 'noexec'; then
        echo "'noexec' option is set for /var/log."
        return 0  # No action needed
    else
        echo "'noexec' option is NOT set for /var/log."
        return 1  # Action needed
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Check if /var/log is mounted
    if mount | grep -q '/var/log'; then
        echo "/var/log partition exists."
        
        # Edit /etc/fstab to add noexec if not already present
        if grep -q '/var/log' /etc/fstab; then
            # Use sed to add noexec to the mounting options
            sed -i.bak "s/\(\/var\/log.*\)\(defaults.*\)/\1\2,noexec/" /etc/fstab
            echo "Updated /etc/fstab with 'noexec' option."
        else
            echo "No entry for /var/log found in /etc/fstab."
            echo "<device> /var/log <fstype> defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
            echo "Added entry for /var/log in /etc/fstab."
        fi

        # Remount /var/log with the new options
        mount -o remount /var/log
        echo "/var/log remounted with 'noexec' option."
    else
        echo "/var/log partition does not exist."
    fi
}

# Main script execution
check_noexec
if [ $? -eq 1 ]; then
    read -p "Do you want to apply remediation to set the 'noexec' option for /var/log? (y/n): " response
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
