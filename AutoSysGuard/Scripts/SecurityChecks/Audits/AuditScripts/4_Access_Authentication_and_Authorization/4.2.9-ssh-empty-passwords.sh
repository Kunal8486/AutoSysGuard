#!/bin/bash

# Function to audit the PermitEmptyPasswords setting
audit_permit_empty_passwords() {
    # Get the current PermitEmptyPasswords setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i "permitemptypasswords")

    # Check if current setting is set to yes
    echo "Current PermitEmptyPasswords setting: $current_setting"
    if echo "$current_setting" | grep -qi "permitemptypasswords yes"; then
        echo "Audit Failed: PermitEmptyPasswords is enabled."
        return 1
    fi

    echo "Audit Passed: PermitEmptyPasswords is disabled."
    return 0
}

# Function to apply remediation
remediate_permit_empty_passwords() {
    # Set the PermitEmptyPasswords in the sshd_config file
    if grep -q '^\h*PermitEmptyPasswords' /etc/ssh/sshd_config; then
        # If PermitEmptyPasswords exists, change it
        sed -i "s/^\h*PermitEmptyPasswords.*/PermitEmptyPasswords no/" /etc/ssh/sshd_config
    else
        # If PermitEmptyPasswords does not exist, add it
        echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: PermitEmptyPasswords set to no."
}

# Main script execution
audit_permit_empty_passwords
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_permit_empty_passwords
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
