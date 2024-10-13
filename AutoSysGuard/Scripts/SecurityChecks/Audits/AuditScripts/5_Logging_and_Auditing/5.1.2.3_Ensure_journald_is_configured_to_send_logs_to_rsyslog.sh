#!/bin/bash

# Function to audit journald configuration for rsyslog forwarding
audit_journald_rsyslog() {
    echo "Auditing journald configuration for rsyslog forwarding..."
    
    # Check for ForwardToSyslog in the configuration file
    forward_to_syslog=$(grep ^\s*ForwardToSyslog /etc/systemd/journald.conf)

    if [[ "$forward_to_syslog" == "ForwardToSyslog=yes" ]]; then
        echo "Audit Passed: journald is configured to forward logs to rsyslog."
        return 0  # Audit passed
    else
        echo "Audit Failed: journald is not configured to forward logs to rsyslog."
        return 1  # Audit failed
    fi
}

# Function to ask user for remediation
ask_for_remediation() {
    read -p "Do you want to apply remediation? (y/n): " answer
    case $answer in
        [Yy]* ) apply_remediation ;;
        [Nn]* ) echo "No remediation applied." ;;
        * ) echo "Invalid input. No remediation applied." ;;
    esac
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Ensure the ForwardToSyslog setting is added or updated
    if grep -q ^\s*ForwardToSyslog /etc/systemd/journald.conf; then
        sed -i 's/^ForwardToSyslog=.*/ForwardToSyslog=yes/' /etc/systemd/journald.conf
    else
        echo "ForwardToSyslog=yes" >> /etc/systemd/journald.conf
    fi

    # Restart the rsyslog service
    systemctl restart rsyslog
    echo "Remediation applied: ForwardToSyslog set to 'yes' and rsyslog service restarted."
}

# Main script execution
if audit_journald_rsyslog; then
    # Audit passed
    echo "journald is configured correctly to send logs to rsyslog."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
