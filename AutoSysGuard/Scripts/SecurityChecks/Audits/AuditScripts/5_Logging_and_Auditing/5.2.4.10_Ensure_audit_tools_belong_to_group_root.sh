#!/bin/bash

# List of audit tools to check
AUDIT_TOOLS=(
    "/sbin/auditctl"
    "/sbin/aureport"
    "/sbin/ausearch"
    "/sbin/autrace"
    "/sbin/auditd"
    "/sbin/augenrules"
)

# Flag to track if any changes were made
CHANGED_GROUP=false

# Check group ownership of each audit tool
for TOOL in "${AUDIT_TOOLS[@]}"; do
    if [[ -f "$TOOL" ]]; then
        # Get the current group
        CURRENT_GROUP=$(stat -c "%G" "$TOOL")

        # Check if the group is not root
        if [[ "$CURRENT_GROUP" != "root" ]]; then
            echo "Changing group for $TOOL: current group ($CURRENT_GROUP)"
            # Change group to root
            chgrp root "$TOOL"
            CHANGED_GROUP=true
        fi
    else
        echo "Warning: $TOOL does not exist."
    fi
done

if [[ "$CHANGED_GROUP" = true ]]; then
    echo "Group ownership has been adjusted for one or more audit tools."
else
    echo "All audit tools are correctly owned by group root."
fi
