#!/bin/bash

# Check current permissions and ownership of /boot/grub/grub.cfg
file="/boot/grub/grub.cfg"
echo "Checking permissions and ownership of $file..."

if [ -f "$file" ]; then
    current_permissions=$(stat -c "%a" $file)
    current_owner=$(stat -c "%u" $file)
    current_group=$(stat -c "%g" $file)

    echo "Current Permissions: $current_permissions"
    echo "Current Owner (UID): $current_owner"
    echo "Current Group (GID): $current_group"

    # Check if permissions and ownership match the desired state (600, root/root)
    if [ "$current_permissions" -eq 600 ] && [ "$current_owner" -eq 0 ] && [ "$current_group" -eq 0 ]; then
        echo "No changes needed. The file already has the correct permissions and ownership."
    else
        echo "The file does not have the correct permissions or ownership."
        echo "Do you want to apply the remediation? (y/n)"
        read -r apply_remediation

        if [ "$apply_remediation" == "y" ]; then
            # Apply remediation
            echo "Applying remediation..."
            chown root:root $file
            chmod u-x,go-rwx $file
            echo "Remediation applied successfully."
        else
            echo "Remediation not applied."
        fi
    fi
else
    echo "$file does not exist!"
fi
