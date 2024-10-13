#!/bin/bash

# Check for auditd configuration file
if [ -f /etc/audit/auditd.conf ]; then
    # Get the directory of the audit log files
    LOG_DIR=$(dirname $(awk -F "=" '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs))

    # Check if log_group is set to either adm or root
    if grep -Piws -- '^\h*log_group\h*=\h*\H+\b' /etc/audit/auditd.conf | grep -Pv -- '(amd)'; then
        echo "log_group parameter is set correctly."
    else
        echo "ERROR: log_group parameter is not set to 'adm' or 'root'."
    fi

    # Find files not owned by the root or adm group
    echo "Checking group ownership for audit log files in $LOG_DIR..."
    UNAUTHORIZED_FILES=$(find "$LOG_DIR" -type f ! -group root ! -group adm)

    if [ -z "$UNAUTHORIZED_FILES" ]; then
        echo "All audit log files are owned by the root or adm group."
    else
        echo "The following audit log files are not owned by the root or adm group:"
        echo "$UNAUTHORIZED_FILES"

        # Change group ownership to adm
        echo "Changing group ownership to 'adm' for the above files..."
        find "$LOG_DIR" -type f ! -group root ! -group adm -exec chgrp adm {} +

        echo "Group ownership changed successfully."
    fi

    # Update the log_group parameter to adm in auditd.conf
    echo "Updating log_group parameter to 'adm' in /etc/audit/auditd.conf..."
    sed -ri 's/^\s*#?\s*log_group\s*=\s*\S+(\s*#.*)?$/log_group = adm\1/' /etc/audit/auditd.conf

    # Restart the audit daemon to apply changes
    echo "Restarting audit daemon to reload configuration..."
    systemctl restart auditd
    echo "Audit daemon restarted successfully."
else
    echo "Error: /etc/audit/auditd.conf not found."
fi
