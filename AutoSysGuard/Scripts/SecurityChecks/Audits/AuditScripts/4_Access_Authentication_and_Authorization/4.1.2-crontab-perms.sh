#!/bin/bash

# Function to audit permissions and ownership on /etc/crontab
audit_crontab() {
    echo "Auditing /etc/crontab permissions and ownership..."
    
    # Get the current ownership and permissions of /etc/crontab
    crontab_permissions=$(stat -Lc '%a' /etc/crontab)
    crontab_owner=$(stat -Lc '%U' /etc/crontab)
    crontab_group=$(stat -Lc '%G' /etc/crontab)

    if [[ "$crontab_permissions" == "600" && "$crontab_owner" == "root" && "$crontab_group" == "root" ]]; then
        echo "PASS: /etc/crontab is correctly configured."
        return 0
    else
        echo "FAIL: /etc/crontab has incorrect permissions or ownership."
        echo "Current Permissions: $crontab_permissions (Expected: 600)"
        echo "Current Owner: $crontab_owner (Expected: root)"
        echo "Current Group: $crontab_group (Expected: root)"
        return 1
    fi
}

# Function to remediate /etc/crontab permissions and ownership
remediate_crontab() {
    echo "Applying remediation for /etc/crontab..."
    
    # Set the correct ownership and permissions
    chown root:root /etc/crontab
    chmod 600 /etc/crontab
    
    echo "Remediation applied: Permissions set to 600, Owner and Group set to root."
}

# Main script
audit_crontab
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_crontab
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
