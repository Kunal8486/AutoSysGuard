#!/bin/bash

# Function to check the audit for /etc/issue
check_issue() {
    echo "Checking /etc/issue for prohibited content and verifying site policy..."
    
    # Check if the contents of /etc/issue match site policy
    echo "Current contents of /etc/issue:"
    cat /etc/issue
    
    # Audit command to check for \m, \r, \s, \v, or references to OS platform
    audit_result=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/issue)
    
    if [[ -n "$audit_result" ]]; then
        echo "Audit failed: /etc/issue contains prohibited content."
        return 1
    else
        echo "Audit passed: /etc/issue is properly configured."
        return 0
    fi
}

# Function to apply remediation
remediate_issue() {
    echo "Applying remediation to /etc/issue..."
    
    # Edit /etc/issue file with the appropriate content according to site policy
    echo "Authorized use only. All activity may be monitored and reported." > /etc/issue
    
    echo "Remediation applied. /etc/issue has been updated."
}

# Main logic
check_issue
if [[ $? -eq 1 ]]; then
    # If audit failed, ask the user to apply remediation
    read -p "Do you want to apply remediation? (y/n): " user_input
    
    if [[ "$user_input" == "y" ]]; then
        remediate_issue
    else
        echo "Remediation not applied. Please ensure /etc/issue is manually configured according to your site policy."
    fi
else
    echo "No remediation is needed."
fi
