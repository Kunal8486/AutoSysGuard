#!/bin/bash

# Function to audit the LogLevel setting
audit_loglevel() {
    # Get the current LogLevel from the SSH configuration
    current_loglevel=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep loglevel | awk '{print $2}')

    # Check if the LogLevel is VERBOSE or INFO
    if [[ "$current_loglevel" == "VERBOSE" || "$current_loglevel" == "INFO" ]]; then
        echo "Audit Passed: LogLevel is set to $current_loglevel."
    else
        echo "Audit Failed: LogLevel is set to $current_loglevel."
        return 1
    fi

    # Check if there are any invalid LogLevel settings in the config file
    if grep -Pis '^\h*loglevel\h+' /etc/ssh/sshd_config | grep -Pvi '(VERBOSE|INFO)' >/dev/null; then
        echo "Audit Failed: Invalid LogLevel configuration found."
        return 1
    else
        echo "Audit Passed: No invalid LogLevel configuration found."
    fi

    return 0
}

# Function to apply remediation
remediate_loglevel() {
    # Set the LogLevel to VERBOSE in the sshd_config file
    if grep -q '^\h*LogLevel' /etc/ssh/sshd_config; then
        # If LogLevel exists, change it
        sed -i 's/^\h*LogLevel.*/LogLevel VERBOSE/' /etc/ssh/sshd_config
    else
        # If LogLevel does not exist, add it
        echo "LogLevel VERBOSE" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: LogLevel set to VERBOSE."
}

# Main script execution
audit_loglevel
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_loglevel
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
