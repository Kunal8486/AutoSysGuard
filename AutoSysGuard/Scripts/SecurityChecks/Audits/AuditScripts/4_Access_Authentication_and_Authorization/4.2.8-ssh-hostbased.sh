#!/bin/bash

# Function to audit the HostbasedAuthentication setting
audit_host_based_authentication() {
    # Get the current HostbasedAuthentication setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i "hostbasedauthentication")

    # Check if current setting is set to yes
    echo "Current HostbasedAuthentication setting: $current_setting"
    if echo "$current_setting" | grep -qi "hostbasedauthentication yes"; then
        echo "Audit Failed: HostbasedAuthentication is enabled."
        return 1
    fi

    echo "Audit Passed: HostbasedAuthentication is disabled."
    return 0
}

# Function to apply remediation
remediate_host_based_authentication() {
    # Set the HostbasedAuthentication in the sshd_config file
    if grep -q '^\h*HostbasedAuthentication' /etc/ssh/sshd_config; then
        # If HostbasedAuthentication exists, change it
        sed -i "s/^\h*HostbasedAuthentication.*/HostbasedAuthentication no/" /etc/ssh/sshd_config
    else
        # If HostbasedAuthentication does not exist, add it
        echo "HostbasedAuthentication no" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: HostbasedAuthentication set to no."
}

# Main script execution
audit_host_based_authentication
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_host_based_authentication
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
