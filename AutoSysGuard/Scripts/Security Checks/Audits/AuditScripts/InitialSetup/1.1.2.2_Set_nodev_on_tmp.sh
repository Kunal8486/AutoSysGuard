#!/bin/bash

# Audit function to check nodev option for /tmp mount
audit_tmp_nodev() {
    echo "Auditing /tmp mount for nodev option..."
    if findmnt -kn /tmp | grep -q "nodev"; then
        echo "The nodev option is set for /tmp."
        return 0  # Return success if nodev is set
    else
        echo "The nodev option is NOT set for /tmp."
        return 1  # Return failure if nodev is not set
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Backup the current fstab
    cp /etc/fstab /etc/fstab.bak

    # Check if the existing entry for /tmp has nodev
    if ! grep -q "nodev" /etc/fstab; then
        # Add nodev option to /tmp entry
        sed -i.bak "/\/tmp/ s/defaults/defaults,rw,nosuid,nodev,noexec/" /etc/fstab
    else
        echo "nodev option is already set in /etc/fstab."
        return
    fi

    # Remount /tmp with the updated options
    mount -o remount /tmp
    echo "Remediation applied successfully."
}

# Main script execution
if audit_tmp_nodev; then
    echo "No remediation needed."
else
    read -p "Do you want to apply the remediation for the nodev option on /tmp? (y/n): " choice
    case "$choice" in
        y|Y )
            apply_remediation
            # Verify the changes
            if audit_tmp_nodev; then
                echo "The nodev option has been set successfully."
            else
                echo "Please verify that the changes were applied correctly."
            fi
            ;;
        n|N )
            echo "Remediation not applied."
            ;;
        * )
            echo "Invalid option. Please choose 'y' or 'n'."
            ;;
    esac
fi
