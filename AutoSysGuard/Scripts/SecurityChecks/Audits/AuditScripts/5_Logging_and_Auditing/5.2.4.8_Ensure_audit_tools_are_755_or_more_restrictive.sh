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
CHANGED_PERMISSIONS=false

# Check permissions and ownership of each audit tool
for TOOL in "${AUDIT_TOOLS[@]}"; do
    if [[ -f "$TOOL" ]]; then
        # Get the current permissions and ownership
        CURRENT_PERMISSIONS=$(stat -c "%a" "$TOOL")
        CURRENT_OWNER=$(stat -c "%U" "$TOOL")
        CURRENT_GROUP=$(stat -c "%G" "$TOOL")

        # Check if permissions are more permissive than 755 or not owned by root
        if [[ "$CURRENT_PERMISSIONS" -gt 755 || "$CURRENT_OWNER" != "root" || "$CURRENT_GROUP" != "root" ]]; then
            echo "Adjusting permissions for $TOOL: current permissions ($CURRENT_PERMISSIONS), owner ($CURRENT_OWNER), group ($CURRENT_GROUP)"
            # Change permissions to 755 and ownership to root:root
            chmod 755 "$TOOL"
            chown root:root "$TOOL"
            CHANGED_PERMISSIONS=true
        fi
    else
        echo "Warning: $TOOL does not exist."
    fi
done

if [[ "$CHANGED_PERMISSIONS" = true ]]; then
    echo "Permissions and ownership have been adjusted for one or more audit tools."
else
    echo "All audit tools are correctly configured."
fi
