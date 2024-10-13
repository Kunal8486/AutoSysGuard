#!/bin/bash

# Function to audit permissions and ownership on /etc/cron.hourly
audit_cron_hourly() {
    echo "Auditing /etc/cron.hourly permissions and ownership..."
    
    # Get the current ownership and permissions of /etc/cron.hourly
    cron_hourly_permissions=$(stat -Lc '%a' /etc/cron.hourly)
    cron_hourly_owner=$(stat -Lc '%U' /etc/cron.hourly)
    cron_hourly_group=$(stat -Lc '%G' /etc/cron.hourly)

    if [[ "$cron_hourly_permissions" == "700" && "$cron_hourly_owner" == "root" && "$cron_hourly_group" == "root" ]]; then
        echo "PASS: /etc/cron.hourly is correctly configured."
        return 0
    else
        echo "FAIL: /etc/cron.hourly has incorrect permissions or ownership."
        echo "Current Permissions: $cron_hourly_permissions (Expected: 700)"
        echo "Current Owner: $cron_hourly_owner (Expected: root)"
        echo "Current Group: $cron_hourly_group (Expected: root)"
        return 1
    fi
}

# Function to remediate /etc/cron.hourly permissions and ownership
remediate_cron_hourly() {
    echo "Applying remediation for /etc/cron.hourly..."
    
    # Set the correct ownership and permissions
    chown root:root /etc/cron.hourly
    chmod 700 /etc/cron.hourly
    
    echo "Remediation applied: Permissions set to 700, Owner and Group set to root."
}

# Main script
audit_cron_hourly
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_cron_hourly
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
