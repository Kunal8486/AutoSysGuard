#!/bin/bash

# Function to check the SSH Banner configuration
audit_ssh_banner() {
    echo "Auditing SSH warning banner configuration..."
    result=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep "^banner /etc/issue.net")
    
    if [ "$result" == "banner /etc/issue.net" ]; then
        echo "PASS: SSH warning banner is correctly configured."
        return 0
    else
        echo "FAIL: SSH warning banner is not correctly configured."
        return 1
    fi
}

# Function to apply the remediation if audit fails
remediate_ssh_banner() {
    echo "Applying remediation..."
    if grep -q "^Banner" /etc/ssh/sshd_config; then
        # Modify the existing Banner line
        sed -i 's|^Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config
    else
        # Add the Banner line if it does not exist
        echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied. Restarting SSH service..."
    systemctl restart sshd
    echo "SSH service restarted."
}

# Main script logic
audit_ssh_banner
if [ $? -ne 0 ]; then
    read -p "The SSH banner is not correctly configured. Would you like to apply remediation? (y/n): " choice
    if [ "$choice" == "y" ]; then
        remediate_ssh_banner
    else
        echo "No remediation applied."
    fi
fi
