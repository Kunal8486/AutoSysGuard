#!/bin/bash

# Audit SSH MaxSessions

audit_maxsessions() {
    # Check MaxSessions
    max_sessions=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -i maxsessions | awk '{print $2}')
    
    # Check if MaxSessions is 10 or less
    if [[ "$max_sessions" -le 10 ]]; then
        echo "Audit Passed: MaxSessions is correctly configured as $max_sessions."
        return 0
    else
        echo "Audit Failed: MaxSessions is $max_sessions, which is greater than 10."
        return 1
    fi
}

remediate_maxsessions() {
    # Set MaxSessions to 10
    sed -i '/^\s*MaxSessions/d' /etc/ssh/sshd_config
    echo "MaxSessions 10" >> /etc/ssh/sshd_config

    echo "Remediation applied: MaxSessions set to 10."
    systemctl restart sshd
}

# Run the audit
audit_maxsessions
audit_status=$?

# If audit fails, ask the user if they want to apply remediation
if [[ "$audit_status" -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" ]]; then
        remediate_maxsessions
    else
        echo "No remediation applied."
    fi
fi
