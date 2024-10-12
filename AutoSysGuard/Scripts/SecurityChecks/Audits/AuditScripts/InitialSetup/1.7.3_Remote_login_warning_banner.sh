#!/bin/bash

# Function to check the audit for /etc/issue.net
check_issue_net() {
    echo "Checking /etc/issue.net for prohibited content and verifying site policy..."
    
    # Display the current contents of /etc/issue.net
    echo "Current contents of /etc/issue.net:"
    cat /etc/issue.net

    # Audit command to check for \m, \r, \s, \v, or references to OS platform
    audit_result=$(grep -E -i "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/issue.net)
    
    if [[ -n "$audit_result" ]]; then
        echo "Audit failed: /etc/issue.net contains prohibited content."
        return 1
    else
        echo "Audit passed: /etc/issue.net is properly configured."
        return 0
    fi
}

# Function to apply remediation
remediate_issue_net() {
    echo "Applying remediation to /etc/issue.net..."
    
    # Edit /etc/issue.net file with the appropriate content according to site policy
    echo "Authorized use only. All activity may be monitored and reported." > /etc/issue.net
    
    echo "Remediation applied. /etc/issue.net has been updated."
}

# Main logic
check_issue_net
if [[ $? -eq 1 ]]; then
    # If audit failed, ask the user to apply remediation
    read -p "Do you want to apply remediation? (y/n): " user_input
    
    if [[ "$user_input" == "y" ]]; then
        remediate_issue_net
    else
        echo "Remediation not applied. Please ensure /etc/issue.net is manually configured according to your site policy."
    fi
else
    echo "No remediation is needed."
fi
