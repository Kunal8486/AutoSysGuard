#!/bin/bash

# Audit SSH LoginGraceTime

audit_logingracetime() {
    # Check LoginGraceTime
    login_grace_time=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep logingracetime | awk '{print $2}')
    
    # Check if LoginGraceTime is between 1 and 60 seconds or 1m
    if [[ "$login_grace_time" =~ ^[1-9][0-9]?$ || "$login_grace_time" == "60" || "$login_grace_time" == "1m" ]]; then
        echo "Audit Passed: LoginGraceTime is correctly configured as $login_grace_time."
        return 0
    else
        echo "Audit Failed: LoginGraceTime is $login_grace_time, which is not between 1 and 60 seconds or 1m."
        return 1
    fi
}

remediate_logingracetime() {
    # Set LoginGraceTime to 60 seconds
    sed -i '/^\s*LoginGraceTime/d' /etc/ssh/sshd_config
    echo "LoginGraceTime 60" >> /etc/ssh/sshd_config

    echo "Remediation applied: LoginGraceTime set to 60 seconds."
    systemctl restart sshd
}

# Run the audit
audit_logingracetime
audit_status=$?

# If audit fails, ask the user if they want to apply remediation
if [[ "$audit_status" -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" ]]; then
        remediate_logingracetime
    else
        echo "No remediation applied."
    fi
fi
