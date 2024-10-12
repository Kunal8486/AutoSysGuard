#!/bin/bash

# Define the configuration file
CONFIG_FILE="/etc/gdm3/custom.conf"

# Function to check the audit condition
check_audit() {
    if grep -Eis '^\s*Enable\s*=\s*true' "$CONFIG_FILE" > /dev/null; then
        echo "Audit Failed: The line 'Enable=true' is present in $CONFIG_FILE."
        return 1
    else
        echo "Audit Passed: The line 'Enable=true' is NOT present in $CONFIG_FILE."
        return 0
    fi
}

# Function to apply remediation
apply_remediation() {
    if grep -Eis '^\s*Enable\s*=\s*true' "$CONFIG_FILE" > /dev/null; then
        sed -i '/^\s*Enable\s*=\s*true/d' "$CONFIG_FILE"
        echo "Remediation applied: The line 'Enable=true' has been removed from $CONFIG_FILE."
    else
        echo "No remediation needed: The line 'Enable=true' is not present."
    fi
}

# Run the audit check
check_audit
AUDIT_RESULT=$?

# Prompt the user for remediation if the audit failed
if [ $AUDIT_RESULT -eq 1 ]; then
    read -p "Do you want to apply remediation? (y/n): " user_input
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "Remediation not applied."
    fi
fi
