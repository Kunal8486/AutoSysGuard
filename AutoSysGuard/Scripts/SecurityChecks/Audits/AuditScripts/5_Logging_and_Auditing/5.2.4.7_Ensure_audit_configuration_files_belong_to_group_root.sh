#!/bin/bash

# Find audit configuration files
AUDIT_FILES=$(find /etc/audit/ -type f \( -name '*.conf' -o -name '*.rules' \))

# Check if there are any audit configuration files
if [[ -z "$AUDIT_FILES" ]]; then
    echo "No audit configuration files found in /etc/audit/."
    exit 1
fi

# Initialize a flag to track any group ownership changes
CHANGED_GROUP=false

# Check group ownership of each audit configuration file
for FILE in $AUDIT_FILES; do
    CURRENT_GROUP=$(stat -c "%G" "$FILE")
    
    # Check if the file is not owned by the root group
    if [[ "$CURRENT_GROUP" != "root" ]]; then
        echo "Current group ($CURRENT_GROUP) for $FILE is not root. Changing group ownership to root..."
        # Change group ownership to root
        chgrp root "$FILE"
        CHANGED_GROUP=true
    fi
done

if [[ "$CHANGED_GROUP" = true ]]; then
    echo "Group ownership changed successfully to root for one or more files."
else
    echo "All audit configuration files are already owned by the root group."
fi
