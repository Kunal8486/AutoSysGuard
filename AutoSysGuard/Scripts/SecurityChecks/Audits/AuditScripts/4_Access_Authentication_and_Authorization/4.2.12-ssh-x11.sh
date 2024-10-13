#!/bin/bash

# Function to audit the X11Forwarding setting
audit_x11forwarding() {
    # Get the current X11Forwarding setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i "x11forwarding")

    # Check if current setting is set to yes
    echo "Current X11Forwarding setting: $current_setting"
    if echo "$current_setting" | grep -qi "x11forwarding yes"; then
        echo "Audit Failed: X11Forwarding is enabled."
        return 1
    fi

    echo "Audit Passed: X11Forwarding is disabled."
    return 0
}

# Function to apply remediation
remediate_x11forwarding() {
    # Set the X11Forwarding in the sshd_config file
    if grep -q '^\h*X11Forwarding' /etc/ssh/sshd_config; then
        # If X11Forwarding exists, change it
        sed -i "s/^\h*X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
    else
        # If X11Forwarding does not exist, add it
        echo "X11Forwarding no" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: X11Forwarding set to no."
}

# Main script execution
audit_x11forwarding
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_x11forwarding
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
