#!/bin/bash

# Check the current permissions, owner, and group of /etc/shells
current_status=$(stat -Lc "%a %u %U %g %G" /etc/shells)
echo "Current status of /etc/shells: $current_status"

# Expected values for permissions and ownership
expected_perms="644"
expected_uid="0"
expected_gid="0"  # GID 0 is for root

# Extract individual values from the current status
current_perms=$(echo $current_status | awk '{print $1}')
current_uid=$(echo $current_status | awk '{print $2}')
current_gid=$(echo $current_status | awk '{print $4}')

# Compare the current status with the expected values
if [[ "$current_perms" == "$expected_perms" && "$current_uid" == "$expected_uid" && "$current_gid" == "$expected_gid" ]]; then
    echo "The /etc/shells file is already configured correctly."
else
    echo "The /etc/shells file is not configured correctly."
    read -p "Do you want to apply the recommended remediation (y/n)? " choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Applying remediation..."
        
        # Set correct ownership and group
        chown root:root /etc/shells

        # Set correct permissions
        chmod u-x,go-wx /etc/shells

        echo "Remediation applied successfully!"
    else
        echo "Remediation skipped."
    fi
fi
