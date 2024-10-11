#!/bin/bash

# Define the finalize rules file
FINALIZE_RULES_FILE="/etc/audit/rules.d/99-finalize.rules"

# Check if the audit configuration is already set to immutable
if grep -qP -- '^\s*-e\s+2\b' "$FINALIZE_RULES_FILE"; then
    echo "Audit configuration is already set to immutable."
else
    # Add the line to set the audit configuration to immutable
    {
        echo "# Ensure audit configuration is immutable"
        echo "-e 2"
    } >> "$FINALIZE_RULES_FILE"
    echo "Added '-e 2' to $FINALIZE_RULES_FILE"
fi

# Load the audit rules into active configuration
augenrules --load

# Check if a reboot is required to apply the changes
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "Reboot required to load rules."
else
    echo "Audit rules loaded successfully."
fi

# Verify the configuration
echo "Verifying the audit configuration..."
grep -Ph -- '^\h*-e\h+2\b' /etc/audit/rules.d/*.rules | tail -1
