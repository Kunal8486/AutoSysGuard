#!/bin/bash

# Function to check the nosuid option for /var/tmp
check_nosuid() {
    echo "Checking if the 'nosuid' option is set for /var/tmp..."
    if findmnt -kn /var/tmp | grep -q 'nosuid'; then
        echo "'nosuid' option is set for /var/tmp."
        return 0  # No action needed
    else
        echo "'nosuid' option is NOT set for /var/tmp."
        return 1  # Action needed
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    # Check if /var/tmp is mounted
    if mount | grep -q '/var/tmp'; then
        echo "/var/tmp partition exists."
        
        # Edit /etc/fstab to add nosuid if not already present
        if grep -q '/var/tmp' /etc/fstab; then
            sed -i.bak "s/\(\/var\/tmp.*\)\(defaults.*\)/\1\2,nosuid/" /etc/fstab
            echo "Updated /etc/fstab with 'nosuid' option."
        else
            echo "No entry for /var/tmp found in /etc/fstab."
            echo "<device> /var/tmp <fstype> defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
            echo "Added entry for /var/tmp in /etc/fstab."
        fi

        # Remount /var/tmp with the new options
        mount -o remount /var/tmp
        echo "/var/tmp remounted with 'nosuid' option."
    else
        echo "/var/tmp partition does not exist."
    fi
}

# Main script execution
check_nosuid
if [ $? -eq 1 ]; then
    read -p "Do you want to apply remediation to set the 'nosuid' option for /var/tmp? (y/n): " response
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
