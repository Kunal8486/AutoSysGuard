#!/bin/bash

# Function to audit the PermitUserEnvironment setting
audit_permit_user_environment() {
    # Get the current PermitUserEnvironment setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i "permituserenvironment")

    # Check if current setting is set to yes
    echo "Current PermitUserEnvironment setting: $current_setting"
    if echo "$current_setting" | grep -qi "permituserenvironment yes"; then
        echo "Audit Failed: PermitUserEnvironment is enabled."
        return 1
    fi

    echo "Audit Passed: PermitUserEnvironment is disabled."
    return 0
}

# Function to apply remediation
remediate_permit_user_environment() {
    # Set the PermitUserEnvironment in the sshd_config file
    if grep -q '^\h*PermitUserEnvironment' /etc/ssh/sshd_config; then
        # If PermitUserEnvironment exists, change it
        sed -i "s/^\h*PermitUserEnvironment.*/PermitUserEnvironment no/" /etc/ssh/sshd_config
    else
        # If PermitUserEnvironment does not exist, add it
        echo "PermitUserEnvironment no" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: PermitUserEnvironment set to no."
}

# Main script execution
audit_permit_user_environment
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_permit_user_environment
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
