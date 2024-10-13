#!/bin/bash

# Function to audit the UsePAM setting
audit_usepam() {
    # Get the current UsePAM setting
    current_usepam=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i usepam | awk '{print $2}')

    # Check if UsePAM is set to yes
    if [[ "$current_usepam" == "yes" ]]; then
        echo "Audit Passed: UsePAM is set to $current_usepam."
    else
        echo "Audit Failed: UsePAM is set to $current_usepam."
        return 1
    fi

    # Check if there are any invalid UsePAM settings in the config file
    if grep -Pis '^\h*UsePAM\h+"?no"?\b' /etc/ssh/sshd_config >/dev/null; then
        echo "Audit Failed: Invalid UsePAM configuration found."
        return 1
    else
        echo "Audit Passed: No invalid UsePAM configuration found."
    fi

    return 0
}

# Function to apply remediation
remediate_usepam() {
    # Set the UsePAM to yes in the sshd_config file
    if grep -q '^\h*UsePAM' /etc/ssh/sshd_config; then
        # If UsePAM exists, change it
        sed -i 's/^\h*UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
    else
        # If UsePAM does not exist, add it
        echo "UsePAM yes" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: UsePAM set to yes."
}

# Main script execution
audit_usepam
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_usepam
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
