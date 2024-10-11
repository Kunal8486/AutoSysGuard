#!/bin/bash

# Check the current permissions, owner, and group of /etc/passwd-
current_status=$(stat -Lc "%a %u %U %g %G" /etc/passwd-)
echo "Current status of /etc/passwd-: $current_status"

# Expected values
expected_status="644 0 root 0 root"

# Compare the current status with the expected status
if [[ "$current_status" == "$expected_status" ]]; then
    echo "The /etc/passwd- file is already configured correctly."
else
    echo "The /etc/passwd- file is not configured correctly."
    read -p "Do you want to apply the recommended remediation (y/n)? " choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Applying remediation..."
        
        # Remove excess permissions and set correct permissions
        chmod u-x,go-wx /etc/passwd-
        # Set the owner to root and group to root
        chown root:root /etc/passwd-

        echo "Remediation applied successfully!"
    else
        echo "Remediation skipped."
    fi
fi
