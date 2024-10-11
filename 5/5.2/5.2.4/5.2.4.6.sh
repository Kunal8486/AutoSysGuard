#!/bin/bash

# Find audit configuration files
AUDIT_FILES=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \))

# Check if there are any audit configuration files
if [[ -z "$AUDIT_FILES" ]]; then
    echo "No audit configuration files found in /etc/audit/."
    exit 1
fi

# Initialize a flag to track any ownership changes
CHANGED_OWNERSHIP=false

# Check ownership of each audit configuration file
for FILE in $AUDIT_FILES; do
    CURRENT_OWNER=$(stat -c "%U" "$FILE")
    
    # Check if the file is not owned by root
    if [[ "$CURRENT_OWNER" != "root" ]]; then
        echo "Current owner ($CURRENT_OWNER) for $FILE is not root. Changing ownership to root..."
        # Change ownership to root
        chown root "$FILE"
        CHANGED_OWNERSHIP=true
    fi
done

if [[ "$CHANGED_OWNERSHIP" = true ]]; then
    echo "Ownership changed successfully to root for one or more files."
else
    echo "All audit configuration files are already owned by root."
fi
