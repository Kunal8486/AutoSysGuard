#!/bin/bash

# Define the configuration file
CONFIG_FILE="/etc/security/pwquality.conf"

# Function to audit the maxrepeat value
audit_maxrepeat() {
    # Check if maxrepeat is set to 3 or less and not 0
    if grep -Pq '^\h*maxrepeat\h*=\h*[1-3]\b' "$CONFIG_FILE"; then
        echo "Audit passed: maxrepeat is set to a valid value."
        return 0
    elif grep -q '^\h*maxrepeat\h*=\h*0\b' "$CONFIG_FILE"; then
        echo "Audit failed: maxrepeat is set to 0, which is not allowed."
        return 1
    else
        echo "Audit failed: maxrepeat is not set or set to a value greater than 3."
        return 1
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation: setting maxrepeat to 3."
    if grep -q '^\h*maxrepeat\h*=' "$CONFIG_FILE"; then
        # If maxrepeat is already present, edit it
        sed -i 's/^\h*maxrepeat\h*=.*/maxrepeat = 3/' "$CONFIG_FILE"
    else
        # If maxrepeat is not present, add it
        echo "maxrepeat = 3" >> "$CONFIG_FILE"
    fi
    echo "Remediation applied: maxrepeat set to 3."
}

# Run the audit
audit_maxrepeat
AUDIT_RESULT=$?

# If audit failed, ask user for remediation
if [ $AUDIT_RESULT -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " user_input
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No changes made."
    fi
fi
