#!/bin/bash

# Function to audit permissions and ownership on /etc/cron.d
audit_cron_d() {
    echo "Auditing /etc/cron.d permissions and ownership..."
    
    # Get the current ownership and permissions of /etc/cron.d
    cron_d_permissions=$(stat -Lc '%a' /etc/cron.d)
    cron_d_owner=$(stat -Lc '%U' /etc/cron.d)
    cron_d_group=$(stat -Lc '%G' /etc/cron.d)

    if [[ "$cron_d_permissions" == "700" && "$cron_d_owner" == "root" && "$cron_d_group" == "root" ]]; then
        echo "PASS: /etc/cron.d is correctly configured."
        return 0
    else
        echo "FAIL: /etc/cron.d has incorrect permissions or ownership."
        echo "Current Permissions: $cron_d_permissions (Expected: 700)"
        echo "Current Owner: $cron_d_owner (Expected: root)"
        echo "Current Group: $cron_d_group (Expected: root)"
        return 1
    fi
}

# Function to remediate /etc/cron.d permissions and ownership
remediate_cron_d() {
    echo "Applying remediation for /etc/cron.d..."
    
    # Set the correct ownership and permissions
    chown root:root /etc/cron.d
    chmod 700 /etc/cron.d
    
    echo "Remediation applied: Permissions set to 700, Owner and Group set to root."
}

# Main script
audit_cron_d
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_cron_d
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
