#!/bin/bash

# Function to check if the nodev option is set for /var/log/audit
check_nodev() {
    echo "Checking if the 'nodev' option is set for /var/log/audit..."
    if findmnt -kn /var/log/audit | grep -q 'nodev'; then
        echo "'nodev' option is set for /var/log/audit."
        return 0  # No action needed
    else
        echo "'nodev' option is NOT set for /var/log/audit."
        return 1  # Action needed
    fi
}

# Function to check if /var/log/audit is mounted
is_audit_mounted() {
    if mount | grep -q '/var/log/audit'; then
        return 0  # Mounted
    else
        return 1  # Not mounted
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Check if /var/log/audit is mounted
    if is_audit_mounted; then
        echo "/var/log/audit partition exists."
        
        # Edit /etc/fstab to add nodev if not already present
        if grep -q '/var/log/audit' /etc/fstab; then
            echo "Entry for /var/log/audit found in /etc/fstab. Updating options..."
            # Use sed to add nodev to the mounting options
            sed -i.bak "s/\(\/var\/log\/audit.*\)\(defaults.*\)/\1\2,nodev/" /etc/fstab
            echo "Updated /etc/fstab with 'nodev' option."
        else
            echo "No entry for /var/log/audit found in /etc/fstab. Adding it now..."
            echo "<device> /var/log/audit <fstype> defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
            echo "Added entry for /var/log/audit in /etc/fstab."
        fi

        # Remount /var/log/audit with the new options
        mount -o remount /var/log/audit
        echo "/var/log/audit remounted with 'nodev' option."
    else
        echo "/var/log/audit partition does not exist. Checking if /var/log is mounted..."
        if mount | grep -q '/var/log'; then
            echo "/var/log is mounted, but /var/log/audit is not."
        else
            echo "Neither /var/log nor /var/log/audit is mounted."
        fi
    fi
}

# Main script execution
check_nodev
if [ $? -eq 1 ]; then
    read -p "Do you want to apply remediation to set the 'nodev' option for /var/log/audit? (y/n): " response
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
