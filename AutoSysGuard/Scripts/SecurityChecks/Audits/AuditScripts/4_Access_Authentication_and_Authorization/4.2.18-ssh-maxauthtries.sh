#!/bin/bash

# Function to audit the MaxAuthTries setting
audit_max_auth_tries() {
    # Get the current MaxAuthTries setting
    current_max_auth_tries=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep maxauthtries | awk '{print $2}')

    # Check if MaxAuthTries is 4 or less
    if [[ "$current_max_auth_tries" -le 4 ]]; then
        echo "Audit Passed: MaxAuthTries is set to $current_max_auth_tries."
    else
        echo "Audit Failed: MaxAuthTries is set to $current_max_auth_tries."
        return 1
    fi

    # Check for any invalid MaxAuthTries settings in the config files
    if grep -Pis '^\h*maxauthtries\h+"?([5-9]|[1-9][0-9]+)\b' /etc/ssh/sshd_config >/dev/null; then
        echo "Audit Failed: Invalid MaxAuthTries configuration found."
        return 1
    else
        echo "Audit Passed: No invalid MaxAuthTries configuration found."
    fi

    return 0
}

# Function to apply remediation
remediate_max_auth_tries() {
    # Set the MaxAuthTries to 4 in the sshd_config file
    if grep -q '^\h*MaxAuthTries' /etc/ssh/sshd_config; then
        # If MaxAuthTries exists, change it
        sed -i 's/^\h*MaxAuthTries.*/MaxAuthTries 4/' /etc/ssh/sshd_config
    else
        # If MaxAuthTries does not exist, add it
        echo "MaxAuthTries 4" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: MaxAuthTries set to 4."
}

# Main script execution
audit_max_auth_tries
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_max_auth_tries
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
