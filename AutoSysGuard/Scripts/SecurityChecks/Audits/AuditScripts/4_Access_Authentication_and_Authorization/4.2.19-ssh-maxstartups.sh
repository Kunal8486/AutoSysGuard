#!/bin/bash

# Function to audit MaxStartups
audit_maxstartups() {
    echo "Auditing SSH MaxStartups configuration..."
    current_maxstartups=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i maxstartups | awk '{print $2}')
    
    if [[ -z "$current_maxstartups" ]]; then
        echo "FAIL: MaxStartups is not set."
        return 1
    elif [[ $current_maxstartups == "10:30:60" ]]; then
        echo "PASS: MaxStartups is correctly configured as 10:30:60."
        return 0
    else
        echo "FAIL: MaxStartups is set to $current_maxstartups (Expected: 10:30:60)."
        return 1
    fi
}

# Function to remediate MaxStartups
remediate_maxstartups() {
    echo "Applying remediation..."
    # Check if MaxStartups is already present, if so, modify it
    if grep -qP '^\s*MaxStartups\b' /etc/ssh/sshd_config; then
        sed -i 's/^\s*MaxStartups.*/MaxStartups 10:30:60/' /etc/ssh/sshd_config
    else
        echo "MaxStartups 10:30:60" >> /etc/ssh/sshd_config
    fi

    echo "Remediation applied: MaxStartups set to 10:30:60."
    # Restart the SSH service to apply changes
    systemctl restart ssh || systemctl restart sshd
}

# Main script
audit_maxstartups
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_maxstartups
    else
        echo "Remediation skipped."
    fi
else
    echo "No remediation required."
fi
