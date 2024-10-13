#!/bin/bash

# Function to audit /tmp mount
audit_tmp_mount() {
    echo "Auditing /tmp mount..."
    
    # Check if /tmp is mounted
    if findmnt -nk /tmp > /dev/null; then
        echo "/tmp is correctly mounted."
        findmnt -nk /tmp
        return 0
    else
        echo "/tmp is not mounted correctly."
        return 1
    fi
}

# Function to apply remediation
remediate_tmp_mount() {
    echo "Applying remediation..."
    
    # Backup the current /etc/fstab file
    cp -v /etc/fstab /etc/fstab.bak

    # Write new /tmp mount configuration
    echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab

    # Create the tmp.mount file if it doesn't exist
    if [ ! -f /etc/systemd/system/tmp.mount ]; then
        cp -v /usr/share/systemd/tmp.mount /etc/systemd/system/
    fi

    # Edit tmp.mount file for customization
    sed -i 's/^\(Options=\).*/\1defaults,rw,nosuid,nodev,noexec,relatime/' /etc/systemd/system/tmp.mount

    # Reload the systemd manager configuration
    systemctl daemon-reload

    # Remount /tmp to apply changes
    mount -o remount /tmp

    echo "Remediation applied successfully."
}

# Main script execution
if audit_tmp_mount; then
    echo "No remediation needed."
else
    read -p "Do you want to apply the remediation for /tmp mount? (y/n): " choice
    case "$choice" in
        y|Y )
            remediate_tmp_mount
            ;;
        n|N )
            echo "Remediation not applied."
            ;;
        * )
            echo "Invalid input. Please enter 'y' or 'n'."
            ;;
    esac
fi
