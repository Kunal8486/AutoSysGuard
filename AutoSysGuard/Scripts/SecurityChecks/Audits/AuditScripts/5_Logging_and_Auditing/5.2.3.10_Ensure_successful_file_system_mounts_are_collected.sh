#!/bin/bash

# Check if UID_MIN is set
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [ -z "$UID_MIN" ]; then
    echo "ERROR: Variable 'UID_MIN' is unset."
    exit 1
fi

# Define the audit rules file
AUDIT_RULES_FILE="/etc/audit/rules.d/50-mounts.rules"

# Create or edit the audit rules file with necessary rules
{
    echo "# Audit rules for monitoring successful file system mounts"
    echo "-a always,exit -F arch=b32 -S mount -F auid>=${UID_MIN} -F auid!=unset -k mounts"
    echo "-a always,exit -F arch=b64 -S mount -F auid>=${UID_MIN} -F auid!=unset -k mounts"
} > "$AUDIT_RULES_FILE"

# Load the audit rules into active configuration
augenrules --load

# Check if a reboot is required to apply the changes
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "Reboot required to load rules."
else
    echo "Audit rules loaded successfully."
fi
