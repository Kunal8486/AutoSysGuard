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
CHANGED_OWNERSHIP=false

# Check ownership of each audit tool
for TOOL in "${AUDIT_TOOLS[@]}"; do
    if [[ -f "$TOOL" ]]; then
        # Get the current owner
        CURRENT_OWNER=$(stat -c "%U" "$TOOL")

        # Check if the owner is not root
        if [[ "$CURRENT_OWNER" != "root" ]]; then
            echo "Changing owner for $TOOL: current owner ($CURRENT_OWNER)"
            # Change ownership to root
            chown root "$TOOL"
            CHANGED_OWNERSHIP=true
        fi
    else
        echo "Warning: $TOOL does not exist."
    fi
done

if [[ "$CHANGED_OWNERSHIP" = true ]]; then
    echo "Ownership has been adjusted for one or more audit tools."
else
    echo "All audit tools are correctly owned by root."
fi
