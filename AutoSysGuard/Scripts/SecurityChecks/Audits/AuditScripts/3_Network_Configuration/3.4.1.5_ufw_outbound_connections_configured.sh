#!/bin/bash

# Function to check UFW outbound rules
check_ufw_status() {
    echo "Checking UFW status..."
    ufw_status=$(ufw status numbered)

    if [[ -z "$ufw_status" ]]; then
        echo "UFW is inactive or no rules found."
        return 1
    else
        echo "Current UFW rules:"
        echo "$ufw_status"
        return 0
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation: Allow all outbound connections on all interfaces..."
    ufw allow out on all
    echo "Remediation applied successfully."
}

# Main script execution
check_ufw_status

# Check if UFW rules are configured correctly
if ! ufw status numbered | grep -q "ALLOW OUT.*on all"; then
    # Prompt user for remediation
    read -p "The outbound rules do not allow all connections. Do you want to apply the remediation? (y/n): " response

    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes were made."
    fi
else
    echo "The outbound rules are already configured to allow all connections."
fi
