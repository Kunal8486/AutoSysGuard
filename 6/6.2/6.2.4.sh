#!/bin/bash

# Check if the shadow group exists and retrieve its members
shadow_members=$(awk -F: '($1=="shadow") {print $NF}' /etc/group)

# Check if the shadow group has any members
if [ -z "$shadow_members" ]; then
    echo "The shadow group is empty. No action needed."
else
    echo -e "The following users are members of the shadow group:\n$shadow_members"

    # Prompt user for remediation
    read -p "Do you want to remove all users from the shadow group? (y/n): " choice

    if [[ "$choice" == "y" ]]; then
        # Remove all users from the shadow group
        sed -ri 's/(^shadow:[^:]*:[^:]*:)([^:]+$)/\1/' /etc/group
        echo "All users have been removed from the shadow group."

        # Change the primary group of any users that had shadow as their primary group
        for user in $shadow_members; do
            # Fetch current primary group of the user
            primary_group=$(id -gn "$user")
            # Fetch a new primary group (assuming 'users' as the default if not set)
            new_primary_group=${primary_group:-users}
            usermod -g "$new_primary_group" "$user"
            echo "Changed primary group of user $user to $new_primary_group."
        done

        echo "All discrepancies have been resolved."
    else
        echo "No changes were made."
    fi
fi
