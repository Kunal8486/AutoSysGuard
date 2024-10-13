#!/bin/bash

# Check for duplicate UIDs
duplicate_uids=$(cut -f3 -d":" /etc/passwd | sort -n | uniq -c | awk '$1 > 1 {print $2}')

# If no duplicate UIDs are found
if [ -z "$duplicate_uids" ]; then
    echo "No duplicate UIDs found. No action needed."
else
    echo "Duplicate UIDs found:"
    echo "$duplicate_uids"

    # Loop through each duplicate UID
    for uid in $duplicate_uids; do
        # Get the list of users with this UID
        users=$(awk -F: "(\$3 == $uid) {print \$1}" /etc/passwd | xargs)

        echo "Duplicate UID ($uid): $users"

        # Prompt user for remediation
        read -p "Do you want to assign unique UIDs to the users listed above? (y/n): " choice

        if [[ "$choice" == "y" ]]; then
            # Loop through each user and assign a new unique UID
            for user in $users; do
                # Find the next available UID (starting from 1000 for regular users)
                new_uid=$(awk -F: '{print $3}' /etc/passwd | sort -n | awk 'BEGIN{uid=1000} {if($1==uid) uid++;} END{print uid}')

                # Change the user's UID to the new unique UID
                usermod -u "$new_uid" "$user"
                echo "Assigned new UID ($new_uid) to user $user."

                # Review files owned by the old UID and change ownership to the new UID
                find / -user "$uid" -exec chown "$user":"$(id -gn "$user")" {} \;
                echo "Updated ownership of files owned by UID ($uid) to new UID ($new_uid)."
            done

            echo "All duplicate UIDs have been resolved."
        else
            echo "No changes were made."
        fi
    done
fi
