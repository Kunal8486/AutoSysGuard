#!/bin/bash

# Function to audit permissions and ownership on /etc/cron.monthly
audit_cron_monthly() {
    echo "Auditing /etc/cron.monthly permissions and ownership..."
    
    # Get the current ownership and permissions of /etc/cron.monthly
    cron_permissions=$(stat -Lc '%a' /etc/cron.monthly)
    cron_owner=$(stat -Lc '%U' /etc/cron.monthly)
    cron_group=$(stat -Lc '%G' /etc/cron.monthly)

    if [[ "$cron_permissions" == "700" && "$cron_owner" == "root" && "$cron_group" == "root" ]]; then
        echo "PASS: /etc/cron.monthly is correctly configured."
        return 0
    else
        echo "FAIL: /etc/cron.monthly has incorrect permissions or ownership."
        echo "Current Permissions: $cron_permissions (Expected: 700)"
        echo "Current Owner: $cron_owner (Expected: root)"
        echo "Current Group: $cron_group (Expected: root)"
        return 1
    fi
}

# Function to remediate /etc/cron.monthly permissions and ownership
remediate_cron_monthly() {
    echo "Applying remediation for /etc/cron.monthly..."
    
    # Set the correct ownership and permissions
    chown root:root /etc/cron.monthly
    chmod 700 /etc/cron.monthly
    
    echo "Remediation applied: Permissions set to 700, Owner and Group set to root."
}

# Main script
audit_cron_monthly
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_cron_monthly
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
