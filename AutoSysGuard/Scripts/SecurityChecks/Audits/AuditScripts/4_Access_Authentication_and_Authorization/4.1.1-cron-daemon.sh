#!/bin/bash

# Function to audit cron service
audit_cron() {
    echo "Checking if cron service is enabled..."
    cron_enabled=$(systemctl is-enabled cron 2>/dev/null)
    
    if [[ $cron_enabled == "enabled" ]]; then
        echo "Cron service is enabled."
    else
        echo "Cron service is not enabled."
        return 1
    fi

    echo "Checking if cron service is active..."
    cron_active=$(systemctl is-active cron 2>/dev/null)
    
    if [[ $cron_active == "active" ]]; then
        echo "Cron service is active."
        return 0
    else
        echo "Cron service is not active."
        return 1
    fi
}

# Function to remediate cron service
remediate_cron() {
    echo "Remediating cron service..."
    systemctl unmask cron
    systemctl --now enable cron
    echo "Cron service has been enabled and started."
}

# Run the audit
audit_cron

# Check audit result
if [[ $? -ne 0 ]]; then
    echo "The cron service is either not enabled or not active."
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    
    if [[ $apply_remediation == "y" || $apply_remediation == "Y" ]]; then
        remediate_cron
    else
        echo "Remediation skipped."
    fi
else
    echo "No issues found with the cron service."
fi
