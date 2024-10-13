#!/bin/bash

# Function to audit permissions and ownership on /etc/cron.weekly
audit_cron_weekly() {
    echo "Auditing /etc/cron.weekly permissions and ownership..."
    
    # Get the current ownership and permissions of /etc/cron.weekly
    cron_weekly_permissions=$(stat -Lc '%a' /etc/cron.weekly)
    cron_weekly_owner=$(stat -Lc '%U' /etc/cron.weekly)
    cron_weekly_group=$(stat -Lc '%G' /etc/cron.weekly)

    if [[ "$cron_weekly_permissions" == "700" && "$cron_weekly_owner" == "root" && "$cron_weekly_group" == "root" ]]; then
        echo "PASS: /etc/cron.weekly is correctly configured."
        return 0
    else
        echo "FAIL: /etc/cron.weekly has incorrect permissions or ownership."
        echo "Current Permissions: $cron_weekly_permissions (Expected: 700)"
        echo "Current Owner: $cron_weekly_owner (Expected: root)"
        echo "Current Group: $cron_weekly_group (Expected: root)"
        return 1
    fi
}

# Function to remediate /etc/cron.weekly permissions and ownership
remediate_cron_weekly() {
    echo "Applying remediation for /etc/cron.weekly..."
    
    # Set the correct ownership and permissions
    chown root:root /etc/cron.weekly
    chmod 700 /etc/cron.weekly
    
    echo "Remediation applied: Permissions set to 700, Owner and Group set to root."
}

# Main script
audit_cron_weekly
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_cron_weekly
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
