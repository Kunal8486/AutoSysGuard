#!/bin/bash

# Define the shells file
SHELLS_FILE="/etc/shells"

# Function to audit for nologin in /etc/shells
audit_nologin() {
    # Check if nologin is listed in the shells file
    if grep -q '/nologin\b' "$SHELLS_FILE"; then
        echo "Audit failed: 'nologin' is listed in $SHELLS_FILE."
        return 1
    else
        echo "Audit passed: 'nologin' is not listed in $SHELLS_FILE."
        return 0
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation: removing lines containing 'nologin' from $SHELLS_FILE."
    # Remove any line containing 'nologin'
    sed -i '/\/nologin\b/d' "$SHELLS_FILE"
    echo "Remediation applied: lines containing 'nologin' have been removed from $SHELLS_FILE."
}

# Run the audit
audit_nologin
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
