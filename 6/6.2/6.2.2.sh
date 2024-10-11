#!/bin/bash

# Check for accounts in /etc/shadow with empty password fields
empty_password_accounts=$(awk -F: '($2 == "") { print $1 " does not have a password" }' /etc/shadow)

if [ -z "$empty_password_accounts" ]; then
    echo "All accounts in /etc/shadow have passwords."
else
    echo "The following accounts do not have passwords:"
    echo "$empty_password_accounts"
    
    # Prompt user for remediation
    read -p "Do you want to lock these accounts? (y/n): " choice

    if [[ "$choice" == "y" ]]; then
        # Lock accounts without passwords
        while IFS= read -r line; do
            username=$(echo "$line" | awk '{print $1}')
            passwd -l "$username"
            echo "Locked account: $username"
        done <<< "$empty_password_accounts"
        
        echo "All accounts without passwords have been locked."
    else
        echo "No changes were made."
    fi
fi
