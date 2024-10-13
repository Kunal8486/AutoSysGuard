#!/bin/bash

# Function to check the permissions, Uid, and Gid for /etc/issue.net
check_issue_net_permissions() {
    echo "Checking permissions, Uid, and Gid of /etc/issue.net..."
    
    # Audit command to check Access permissions, Uid, and Gid
    audit_result=$(stat -Lc 'Access: (%#a/%A) Uid: (%u/%U) Gid: (%g/%G)' /etc/issue.net)
    echo "$audit_result"
    
    # Extract actual values for comparison
    access=$(stat -c %a /etc/issue.net)
    uid=$(stat -c %u /etc/issue.net)
    gid=$(stat -c %g /etc/issue.net)
    
    # Checking if the Access is 644 or more restrictive, and if Uid and Gid are 0/root
    if [[ "$access" -le 644 && "$uid" -eq 0 && "$gid" -eq 0 ]]; then
        echo "Audit passed: /etc/issue.net has the correct permissions, Uid, and Gid."
        return 0
    else
        echo "Audit failed: /etc/issue.net does not have the correct permissions, Uid, or Gid."
        return 1
    fi
}

# Function to apply remediation
remediate_issue_net_permissions() {
    echo "Applying remediation to /etc/issue.net..."
    
    # Set ownership to root:root and correct permissions
    chown root:root $(readlink -e /etc/issue.net)
    chmod u-x,go-wx $(readlink -e /etc/issue.net)
    
    echo "Remediation applied. Permissions and ownership of /etc/issue.net have been updated."
}

# Main logic
check_issue_net_permissions
if [[ $? -eq 1 ]]; then
    # If audit failed, ask the user to apply remediation
    read -p "Do you want to apply remediation? (y/n): " user_input
    
    if [[ "$user_input" == "y" ]]; then
        remediate_issue_net_permissions
    else
        echo "Remediation not applied. Please ensure /etc/issue.net has the correct permissions and ownership manually."
    fi
else
    echo "No remediation is needed."
fi
