#!/bin/bash

# Function to audit the IgnoreRhosts setting
audit_ignoreRhosts() {
    # Get the current IgnoreRhosts setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i "ignorerhosts")

    # Check if current setting is set to no
    echo "Current IgnoreRhosts setting: $current_setting"
    if echo "$current_setting" | grep -qi "ignorerhosts no"; then
        echo "Audit Failed: IgnoreRhosts is disabled."
        return 1
    fi

    echo "Audit Passed: IgnoreRhosts is enabled."
    return 0
}

# Function to apply remediation
remediate_ignoreRhosts() {
    # Set the IgnoreRhosts in the sshd_config file
    if grep -q '^\h*IgnoreRhosts' /etc/ssh/sshd_config; then
        # If IgnoreRhosts exists, change it
        sed -i "s/^\h*IgnoreRhosts.*/IgnoreRhosts yes/" /etc/ssh/sshd_config
    else
        # If IgnoreRhosts does not exist, add it
        echo "IgnoreRhosts yes" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: IgnoreRhosts set to yes."
}

# Main script execution
audit_ignoreRhosts
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_ignoreRhosts
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
