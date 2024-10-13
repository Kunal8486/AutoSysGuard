#!/bin/bash

# Check for duplicate group names in /etc/group
echo "Checking for duplicate group names in /etc/group..."
duplicate_group_names=$(cut -d: -f1 /etc/group | sort | uniq -d)

# If no duplicate group names are found
if [ -z "$duplicate_group_names" ]; then
    echo "No duplicate group names found. No action needed."
else
    echo "Duplicate group names found:"
    echo "$duplicate_group_names"

    # Loop through each duplicate group name
    for groupname in $duplicate_group_names; do
        echo "Duplicate group name: $groupname"

        # Prompt user for remediation
        read -p "Do you want to assign a unique group name to $groupname? (y/n): " choice

        if [[ "$choice" == "y" ]]; then
            # Get the first GID for the duplicate group
            first_gid=$(awk -F: -v group="$groupname" '($1 == group) { print $3; exit }' /etc/group)

            echo "Current GID for $groupname: $first_gid"

            # Get the new group name from the user
            read -p "Enter a new unique group name for $groupname: " new_groupname

            # Check if the new group name already exists
            if getent group "$new_groupname" &>/dev/null; then
                echo "Error: Group name $new_groupname already exists. Please choose a different group name."
                continue
            fi

            # Change the group name to the new unique group name
            groupmod -n "$new_groupname" "$groupname"
            echo "Changed group name from $groupname to $new_groupname."

            # Inform about group ownership change
            echo "Group ownerships for GID $first_gid will now reflect the new group name."
        else
            echo "No changes were made for group name $groupname."
        fi
    done
fi
