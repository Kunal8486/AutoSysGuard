#!/bin/bash

# Check for audit configuration files
AUDIT_FILES=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \))

# Verify if there are any audit configuration files
if [[ -z "$AUDIT_FILES" ]]; then
    echo "No audit configuration files found in /etc/audit/."
    exit 1
fi

# Initialize a flag to track any permission changes
CHANGED_PERMISSIONS=false

# Check permissions of each audit configuration file
for FILE in $AUDIT_FILES; do
    CURRENT_PERMISSIONS=$(stat -Lc "%a" "$FILE")
    
    # Check if permissions are more permissive than 0640
    if [[ "$CURRENT_PERMISSIONS" -gt 640 ]]; then
        echo "Current permissions ($CURRENT_PERMISSIONS) for $FILE are too permissive. Changing to 0640..."
        # Change permissions to 0640
        chmod u-x,g-wx,o-rwx "$FILE"
        CHANGED_PERMISSIONS=true
    fi
done

if [[ "$CHANGED_PERMISSIONS" = true ]]; then
    echo "Permissions changed successfully to 0640 for one or more files."
else
    echo "All audit configuration files already have appropriate permissions."
fi
