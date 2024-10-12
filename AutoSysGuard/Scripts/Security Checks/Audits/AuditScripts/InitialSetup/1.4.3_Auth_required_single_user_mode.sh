#!/bin/bash

# Function to check if the root user has a password set
check_root_password() {
    # Check for a valid password hash for the root user
    if grep -Eq '^root:\$[0-9]' /etc/shadow || grep -Eq '^root:\$y\$' /etc/shadow; then
        echo "Root user has a password set."
        return 0
    else
        echo "Audit check failed: root is locked."
        return 1
    fi
}

# Check the root password status
if check_root_password; then
    exit 0
else
    # Ask the user if they want to apply remediation
    read -p "Do you want to set a password for the root user? (y/n): " answer
    if [[ "$answer" == "y" ]]; then
        # Apply remediation by setting a new password for the root user
        passwd root
        
        # Re-check if the root password is set after remediation
        if check_root_password; then
            echo "Password successfully set, and root user is no longer locked."
        else
            echo "Failed to verify: root is still locked after setting the password."
        fi
    else
        echo "No changes made."
    fi
fi
