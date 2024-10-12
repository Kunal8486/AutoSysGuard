#!/bin/bash

# Function to check the audit
check_motd() {
    echo "Checking /etc/motd for prohibited content..."
    
    # Audit command to check for \m, \r, \s, \v, or references to OS platform
    audit_result=$(grep -Eis "(\\\v|\\\r|\\\m|\\\s|$(grep '^ID=' /etc/os-release | cut -d= -f2 | sed -e 's/\"//g'))" /etc/motd)
    
    if [[ -n "$audit_result" ]]; then
        echo "Audit failed: /etc/motd contains prohibited content."
        return 1
    else
        echo "Audit passed: /etc/motd is properly configured."
        return 0
    fi
}

# Function to apply remediation
remediate_motd() {
    echo "Applying remediation to /etc/motd..."
    
    # Edit /etc/motd file with the appropriate content or remove it
    echo "Authorized use only. All activity may be monitored and reported." > /etc/motd
    
    echo "Remediation applied. /etc/motd has been updated."
}

# Main logic
check_motd
if [[ $? -eq 1 ]]; then
    # If audit failed, ask the user to apply remediation
    read -p "Do you want to apply remediation? (y/n): " user_input
    
    if [[ "$user_input" == "y" ]]; then
        remediate_motd
    else
        echo "Remediation not applied. Please ensure /etc/motd is manually configured according to your site policy."
    fi
else
    echo "No remediation is needed."
fi
