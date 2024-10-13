#!/bin/bash

# Check for accounts with UID 0
echo "Checking for accounts with UID 0..."

# Get users with UID 0
users_with_uid_0=$(awk -F: '($3 == 0) { print $1 }' /etc/passwd)

# Check if there are any accounts with UID 0 other than root
if [[ "$users_with_uid_0" != "root" ]]; then
    echo "The following accounts have UID 0:"
    echo "$users_with_uid_0"
else
    echo "Only 'root' has UID 0."
    exit 0
fi

# Remediation prompt
read -p "Do you want to remove or change the UID of these accounts? (y/n): " choice

if [[ "$choice" == "y" ]]; then
    for user in $users_with_uid_0; do
        if [[ "$user" != "root" ]]; then
            # Prompt for action
            read -p "Do you want to remove the user '$user' or change their UID? (remove/change): " action
            if [[ "$action" == "remove" ]]; then
                # Remove the user
                userdel "$user"
                echo "User '$user' has been removed."
            elif [[ "$action" == "change" ]]; then
                # Change the user's UID to a new value
                read -p "Enter a new UID for user '$user': " new_uid
                usermod -u "$new_uid" "$user"
                echo "User '$user' has been assigned a new UID: $new_uid."
            else
                echo "Invalid action. No changes made for user '$user'."
            fi
        fi
    done
else
    echo "No changes were made."
fi
