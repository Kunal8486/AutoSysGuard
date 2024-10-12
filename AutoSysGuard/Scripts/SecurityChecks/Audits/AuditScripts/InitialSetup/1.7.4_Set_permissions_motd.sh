#!/bin/bash

# Function to check the permissions, Uid, and Gid for /etc/issue
check_issue_permissions() {
    echo "Checking permissions, Uid, and Gid of /etc/issue..."
    
    # Audit command to check Access permissions, Uid, and Gid
    audit_result=$(stat -Lc 'Access: (%#a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/issue)
    echo "$audit_result"
    
    # Extract actual values for comparison
    access=$(stat -c %a /etc/issue)
    uid=$(stat -c %u /etc/issue)
    gid=$(stat -c %g /etc/issue)
    
    # Checking if the Access is 644 or more restrictive, and if Uid and Gid are 0/root
    if [[ "$access" -le 644 && "$uid" -eq 0 && "$gid" -eq 0 ]]; then
        echo "Audit passed: /etc/issue has the correct permissions, Uid, and Gid."
        return 0
    else
        echo "Audit failed: /etc/issue does not have the correct permissions, Uid, or Gid."
        return 1
    fi
}

# Function to apply remediation
remediate_issue_permissions() {
    echo "Applying remediation to /etc/issue..."
    
    # Set ownership to root:root and correct permissions
    chown root:root $(readlink -e /etc/issue)
    chmod u-x,go-wx $(readlink -e /etc/issue)
    
    echo "Remediation applied. Permissions and ownership of /etc/issue have been updated."
}

# Main logic
check_issue_permissions
if [[ $? -eq 1 ]]; then
    # If audit failed, ask the user to apply remediation
    read -p "Do you want to apply remediation? (y/n): " user_input
    
    if [[ "$user_input" == "y" ]]; then
        remediate_issue_permissions
    else
        echo "Remediation not applied. Please ensure /etc/issue has the correct permissions and ownership manually."
    fi
else
    echo "No remediation is needed."
fi
