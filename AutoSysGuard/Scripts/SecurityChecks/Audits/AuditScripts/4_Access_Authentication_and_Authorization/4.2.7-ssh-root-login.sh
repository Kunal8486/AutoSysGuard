#!/bin/bash

# Function to audit the PermitRootLogin setting
audit_permit_root_login() {
    # Get the current PermitRootLogin setting
    current_permit_root_login=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep permitrootlogin | awk '{print $2}')

    # Check if PermitRootLogin is set to no
    if [[ "$current_permit_root_login" == "no" ]]; then
        echo "Audit Passed: PermitRootLogin is set to $current_permit_root_login."
    else
        echo "Audit Failed: PermitRootLogin is set to $current_permit_root_login."
        return 1
    fi

    # Check for any invalid PermitRootLogin settings in the config files
    if grep -Pis '^\h*PermitRootLogin\h+"?(yes|prohibit-password|forced-commands-only)"?\b' /etc/ssh/sshd_config /etc/ssh/ssh_config.d/*.conf >/dev/null; then
        echo "Audit Failed: Invalid PermitRootLogin configuration found."
        return 1
    else
        echo "Audit Passed: No invalid PermitRootLogin configuration found."
    fi

    return 0
}

# Function to apply remediation
remediate_permit_root_login() {
    # Set the PermitRootLogin to no in the sshd_config file
    if grep -q '^\h*PermitRootLogin' /etc/ssh/sshd_config; then
        # If PermitRootLogin exists, change it
        sed -i 's/^\h*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    else
        # If PermitRootLogin does not exist, add it
        echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: PermitRootLogin set to no."
}

# Main script execution
audit_permit_root_login
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_permit_root_login
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
