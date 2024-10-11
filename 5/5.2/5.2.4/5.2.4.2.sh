#!/bin/bash

# Check for auditd configuration file
if [ -f /etc/audit/auditd.conf ]; then
    # Get the directory of the audit log files
    LOG_DIR=$(dirname $(awk -F "=" '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs))

    # Find files not owned by the root user
    echo "Checking ownership for audit log files in $LOG_DIR..."
    UNAUTHORIZED_FILES=$(find "$LOG_DIR" -type f ! -user root)

    if [ -z "$UNAUTHORIZED_FILES" ]; then
        echo "All audit log files are owned by the root user."
    else
        echo "The following audit log files are not owned by the root user:"
        echo "$UNAUTHORIZED_FILES"

        # Change ownership to root
        echo "Changing ownership to root for the above files..."
        find "$LOG_DIR" -type f ! -user root -exec chown root {} +

        echo "Ownership changed successfully."
    fi
else
    echo "Error: /etc/audit/auditd.conf not found."
fi
