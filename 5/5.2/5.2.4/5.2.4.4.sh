#!/bin/bash

# Check for auditd configuration file
if [ -f /etc/audit/auditd.conf ]; then
    # Get the directory of the audit log files
    LOG_DIR=$(dirname "$(awk -F "=" '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs)")

    # Check the permissions of the audit log directory
    CURRENT_PERMISSIONS=$(stat -Lc "%a" "$LOG_DIR")

    # Verify if the permissions are 0750 or more restrictive
    if [[ "$CURRENT_PERMISSIONS" -le 750 ]]; then
        echo "Audit log directory permissions are correct: $CURRENT_PERMISSIONS"
    else
        echo "Current permissions ($CURRENT_PERMISSIONS) are too permissive. Changing to 0750..."
        # Change permissions to 0750
        chmod g-w,o-rwx "$LOG_DIR"
        echo "Permissions changed successfully to 0750."
    fi
else
    echo "Error: /etc/audit/auditd.conf not found."
fi
