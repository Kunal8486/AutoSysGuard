#!/bin/bash

# Function to audit permissions and ownership on /etc/cron.daily
audit_cron_daily() {
    echo "Auditing /etc/cron.daily permissions and ownership..."
    
    # Get the current ownership and permissions of /etc/cron.daily
    cron_daily_permissions=$(stat -Lc '%a' /etc/cron.daily)
    cron_daily_owner=$(stat -Lc '%U' /etc/cron.daily)
    cron_daily_group=$(stat -Lc '%G' /etc/cron.daily)

    if [[ "$cron_daily_permissions" == "700" && "$cron_daily_owner" == "root" && "$cron_daily_group" == "root" ]]; then
        echo "PASS: /etc/cron.daily is correctly configured."
        return 0
    else
        echo "FAIL: /etc/cron.daily has incorrect permissions or ownership."
        echo "Current Permissions: $cron_daily_permissions (Expected: 700)"
        echo "Current Owner: $cron_daily_owner (Expected: root)"
        echo "Current Group: $cron_daily_group (Expected: root)"
        return 1
    fi
}

# Function to remediate /etc/cron.daily permissions and ownership
remediate_cron_daily() {
    echo "Applying remediation for /etc/cron.daily..."
    
    # Set the correct ownership and permissions
    chown root:root /etc/cron.daily
    chmod 700 /etc/cron.daily
    
    echo "Remediation applied: Permissions set to 700, Owner and Group set to root."
}

# Main script
audit_cron_daily
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_cron_daily
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
