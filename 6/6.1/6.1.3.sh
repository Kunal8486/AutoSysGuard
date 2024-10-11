#!/bin/bash

# Check the current permissions, owner, and group of /etc/group
current_status=$(stat -Lc "%a %u %U %g %G" /etc/group)
echo "Current status of /etc/group: $current_status"

# Expected values
expected_status="644 0 root 0 root"

# Compare the current status with the expected status
if [[ "$current_status" == "$expected_status" ]]; then
    echo "The /etc/group file is already configured correctly."
else
    echo "The /etc/group file is not configured correctly."
    read -p "Do you want to apply the recommended remediation (y/n)? " choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Applying remediation..."
        
        # Remove excess permissions and set correct permissions
        chmod u-x,go-wx /etc/group
        # Set the owner to root and group to root
        chown root:root /etc/group

        echo "Remediation applied successfully!"
    else
        echo "Remediation skipped."
    fi
fi
