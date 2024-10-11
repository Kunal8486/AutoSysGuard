#!/bin/bash

# Check for duplicate usernames in /etc/passwd
echo "Checking for duplicate usernames in /etc/passwd..."
duplicate_usernames=$(cut -d: -f1 /etc/passwd | sort | uniq -d)

# If no duplicate usernames are found
if [ -z "$duplicate_usernames" ]; then
    echo "No duplicate usernames found. No action needed."
else
    echo "Duplicate usernames found:"
    echo "$duplicate_usernames"

    # Loop through each duplicate username
    for username in $duplicate_usernames; do
        echo "Duplicate username: $username"

        # Prompt user for remediation
        read -p "Do you want to assign a unique username to $username? (y/n): " choice

        if [[ "$choice" == "y" ]]; then
            # Find the first UID for the duplicate username
            first_uid=$(awk -F: -v user="$username" '($1 == user) { print $3; exit }' /etc/passwd)

            echo "Current UID for $username: $first_uid"

            # Get the new username from the user
            read -p "Enter a new unique username for $username: " new_username

            # Check if the new username already exists
            if id "$new_username" &>/dev/null; then
                echo "Error: Username $new_username already exists. Please choose a different username."
                continue
            fi

            # Change the username to the new unique username
            usermod -l "$new_username" "$username"
            echo "Changed username from $username to $new_username."

            # Inform about ownership change
            echo "File ownerships for UID $first_uid will now reflect the new username."
        else
            echo "No changes were made for username $username."
        fi
    done
fi
