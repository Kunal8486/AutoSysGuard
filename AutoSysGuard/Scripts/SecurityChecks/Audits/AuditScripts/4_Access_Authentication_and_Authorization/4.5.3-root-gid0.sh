#!/usr/bin/env bash
{
    # Audit: Check if the root user's default group is GID 0
    root_gid=$(grep "^root:" /etc/passwd | cut -f4 -d:)

    if [ "$root_gid" -eq 0 ]; then
        echo "Audit passed: Root user's default group is GID 0."
    else
        echo "Audit failed: Root user's default group is not GID 0 (Current GID: $root_gid)."

        # Prompt user for remediation
        read -p "Would you like to apply remediation? (y/n): " apply_remed
        if [[ "$apply_remed" == "y" ]]; then
            echo "Applying remediation..."

            # Remediation: Set the root user's default group to GID 0
            usermod -g 0 root

            # Verify the change
            new_gid=$(grep "^root:" /etc/passwd | cut -f4 -d:)
            if [ "$new_gid" -eq 0 ]; then
                echo "Remediation successful: Root user's default group is now GID 0."
            else
                echo "Remediation failed: Unable to set the root user's default group to GID 0."
            fi
        else
            echo "No remediation applied."
        fi
    fi
}
