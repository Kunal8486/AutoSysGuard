#!/bin/bash

# Initialize a variable to track discrepancies
discrepancies=""

# Check for groups in /etc/passwd that do not exist in /etc/group
for group_id in $(cut -s -d: -f4 /etc/passwd | sort -u); do
    if ! grep -q -P "^.*?:[^:]*:$group_id:" /etc/group; then
        discrepancies+="Group $group_id is referenced by /etc/passwd but does not exist in /etc/group\n"
    fi
done

# Check if there are any discrepancies
if [ -z "$discrepancies" ]; then
    echo "All groups referenced in /etc/passwd exist in /etc/group."
else
    echo -e "The following discrepancies were found:\n$discrepancies"
    
    # Prompt user for remediation
    read -p "Do you want to delete these groups from /etc/passwd? (y/n): " choice

    if [[ "$choice" == "y" ]]; then
        while IFS= read -r line; do
            group_id=$(echo "$line" | awk '{print $NF}' | tr -d '[:space:]')
            sed -i "/:.*:$group_id:/d" /etc/passwd
            echo "Deleted group $group_id from /etc/passwd."
        done <<< "$discrepancies"
        
        echo "All discrepancies have been resolved."
    else
        echo "No changes were made."
    fi
fi
