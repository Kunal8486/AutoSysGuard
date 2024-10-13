#!/bin/bash

# Function to audit SSH settings
audit_ssh_settings() {
    local interval
    local count_max

    # Get current SSH settings
    interval=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep clientaliveinterval | awk '{print $2}')
    count_max=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep clientalivecountmax | awk '{print $2}')

    # Check for ClientAliveInterval
    if [[ -z "$interval" || "$interval" -le 0 ]]; then
        echo "Audit failed: ClientAliveInterval is not set or is set to 0."
        return 1
    else
        echo "ClientAliveInterval is set to $interval."
    fi

    # Check for ClientAliveCountMax
    if [[ -z "$count_max" || "$count_max" -le 0 ]]; then
        echo "Audit failed: ClientAliveCountMax is not set or is set to 0."
        return 1
    else
        echo "ClientAliveCountMax is set to $count_max."
    fi

    echo "Audit passed: Both settings are configured correctly."
    return 0
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Set desired values
    echo "ClientAliveInterval 15" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 3" >> /etc/ssh/sshd_config

    # Restart SSH service to apply changes
    if systemctl restart sshd 2>/dev/null; then
        echo "Remediation applied: ClientAliveInterval set to 15 and ClientAliveCountMax set to 3."
    elif systemctl restart ssh 2>/dev/null; then
        echo "Remediation applied: ClientAliveInterval set to 15 and ClientAliveCountMax set to 3."
    else
        echo "Failed to restart SSH service. Please check if SSH is installed."
    fi
}

# Main script execution
if audit_ssh_settings; then
    exit 0
else
    read -p "Do you want to apply remediation? (y/n): " user_input
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No changes were made."
    fi
fi
