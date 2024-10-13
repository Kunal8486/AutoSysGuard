#!/bin/bash

# Function to audit the AllowTcpForwarding setting
audit_allow_tcp_forwarding() {
    # Get the current AllowTcpForwarding setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i allowtcpforwarding)

    # Check if the AllowTcpForwarding is set to no
    if [[ "$current_setting" == "allowtcpforwarding no" ]]; then
        echo "Audit Passed: AllowTcpForwarding is set to $current_setting."
    else
        echo "Audit Failed: AllowTcpForwarding is set to $current_setting."
        return 1
    fi

    # Check for any AllowTcpForwarding yes in the sshd_config file
    if grep -Pis '^\h*AllowTcpForwarding\h+"?yes\b' /etc/ssh/sshd_config >/dev/null; then
        echo "Audit Failed: Invalid AllowTcpForwarding configuration found."
        return 1
    else
        echo "Audit Passed: No invalid AllowTcpForwarding configuration found."
    fi

    return 0
}

# Function to apply remediation
remediate_allow_tcp_forwarding() {
    # Set the AllowTcpForwarding to no in the sshd_config file
    if grep -q '^\h*AllowTcpForwarding' /etc/ssh/sshd_config; then
        # If AllowTcpForwarding exists, change it
        sed -i 's/^\h*AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config
    else
        # If AllowTcpForwarding does not exist, add it
        echo "AllowTcpForwarding no" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: AllowTcpForwarding set to no."
}

# Main script execution
audit_allow_tcp_forwarding
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_allow_tcp_forwarding
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
