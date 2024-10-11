#!/bin/bash

# Run grpck to check for inconsistencies in /etc/group
echo "Running grpck to check for inconsistencies in /etc/group..."
grpck_output=$(grpck -n)  # -n flag to run in non-interactive mode

if [ -z "$grpck_output" ]; then
    echo "No inconsistencies found in /etc/group."
else
    echo "Inconsistencies found in /etc/group:"
    echo "$grpck_output"

    # Prompt user for remediation
    read -p "Do you want to resolve these inconsistencies? (y/n): " choice

    if [[ "$choice" == "y" ]]; then
        echo "Please review the output of grpck above and correct any issues manually."
    else
        echo "No changes were made."
    fi
fi

# Check for duplicate GIDs
duplicate_gids=$(cut -d: -f3 /etc/group | sort | uniq -d)

# If no duplicate GIDs are found
if [ -z "$duplicate_gids" ]; then
    echo "No duplicate GIDs found. No action needed."
else
    echo "Duplicate GIDs found:"
    echo "$duplicate_gids"

    # Loop through each duplicate GID
    for gid in $duplicate_gids; do
        # Get the list of groups with this GID
        groups=$(awk -F: "(\$3 == $gid) {print \$1}" /etc/group | xargs)

        echo "Duplicate GID ($gid): $groups"

        # Prompt user for remediation
        read -p "Do you want to assign unique GIDs to the groups listed above? (y/n): " choice

        if [[ "$choice" == "y" ]]; then
            # Loop through each group and assign a new unique GID
            for group in $groups; do
                # Find the next available GID (starting from 1000 for regular groups)
                new_gid=$(awk -F: '{print $3}' /etc/group | sort -n | awk 'BEGIN{gid=1000} {if($1==gid) gid++;} END{print gid}')

                # Change the group's GID to the new unique GID
                groupmod -g "$new_gid" "$group"
                echo "Assigned new GID ($new_gid) to group $group."

                # Review files owned by the old GID and change ownership to the new GID
                find / -group "$gid" -exec chgrp "$group" {} \;
                echo "Updated ownership of files owned by GID ($gid) to new GID ($new_gid)."
            done

            echo "All duplicate GIDs have been resolved."
        else
            echo "No changes were made."
        fi
    done
fi
