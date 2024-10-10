#!/bin/bash

# Check for auditd configuration file
if [ -f /etc/audit/auditd.conf ]; then
    # Get the directory of the audit log files
    LOG_DIR=$(dirname $(awk -F "=" '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs))

    # Find files with permissions more permissive than 0640
    echo "Checking permissions for audit log files in $LOG_DIR..."
    PERMISSIVE_FILES=$(find "$LOG_DIR" -type f -perm /0137)

    if [ -z "$PERMISSIVE_FILES" ]; then
        echo "All audit log files have the correct permissions (0640 or less)."
    else
        echo "The following audit log files have permissions more permissive than 0640:"
        echo "$PERMISSIVE_FILES"

        # Change permissions to 0640
        echo "Adjusting permissions to 0640 for the above files..."
        find "$LOG_DIR" -type f -perm /0137 -exec chmod u-x,g-wx,o-rwx {} +

        echo "Permissions adjusted successfully."
    fi
else
    echo "Error: /etc/audit/auditd.conf not found."
fi
