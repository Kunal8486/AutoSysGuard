#!/bin/bash

# Function to check and remediate file permissions and ownership
remediate_file() {
    local file=$1
    if [ -e "$file" ]; then
        current_status=$(stat -Lc "%n %a %u %U %g %G" "$file")
        echo "Current status of $file: $current_status"

        # Expected permissions and ownership
        expected_perms="600"
        expected_uid="0"
        expected_gid="0"

        # Extract individual values from the current status
        current_perms=$(echo $current_status | awk '{print $2}')
        current_uid=$(echo $current_status | awk '{print $3}')
        current_gid=$(echo $current_status | awk '{print $5}')

        # Compare the current status with the expected values
        if [[ "$current_perms" == "$expected_perms" && "$current_uid" == "$expected_uid" && "$current_gid" == "$expected_gid" ]]; then
            echo "$file is already configured correctly."
        else
            echo "$file is not configured correctly."
            read -p "Do you want to apply the recommended remediation (y/n)? " choice

            if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                echo "Applying remediation for $file..."

                # Set correct ownership and group
                chown root:root "$file"

                # Set correct permissions
                chmod u-x,go-rwx "$file"

                echo "Remediation applied successfully for $file!"
            else
                echo "Remediation for $file skipped."
            fi
        fi
    else
        echo "$file does not exist."
    fi
}

# Check and remediate /etc/security/opasswd
remediate_file "/etc/security/opasswd"

# Check and remediate /etc/security/opasswd.old
remediate_file "/etc/security/opasswd.old"
