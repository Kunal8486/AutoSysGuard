#!/bin/bash

# Function to audit if journald is configured to send logs to rsyslog
audit_journald_rsyslog() {
    echo "Auditing journald configuration for rsyslog forwarding..."

    # Checking if ForwardToSyslog is set to 'yes' in any of the configuration files
    forwarding_status=$(grep -Psi '^\h*ForwardToSyslog\h*=\h*yes\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/* 2>/dev/null)

    if [[ "$forwarding_status" != "" ]]; then
        echo "Audit: journald is configured to forward logs to rsyslog."
        prompt_remediation
    else
        echo "Audit: journald is not configured to forward logs to rsyslog."
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to apply the remediation
    read -p "Do you want to remove ForwardToSyslog configuration? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_journald_rsyslog
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to remove ForwardToSyslog configuration
remediate_journald_rsyslog() {
    echo "Remediation: Removing ForwardToSyslog configuration..."

    # Removing the ForwardToSyslog setting from /etc/systemd/journald.conf
    sudo sed -i '/^\s*ForwardToSyslog=/d' /etc/systemd/journald.conf

    # Removing the ForwardToSyslog setting from any custom configuration files
    for conf_file in /etc/systemd/journald.conf.d/*.conf; do
        if [[ -f "$conf_file" ]]; then
            sudo sed -i '/^\s*ForwardToSyslog=/d' "$conf_file"
        fi
    done

    # Restarting the journald service
    sudo systemctl restart systemd-journald

    if [ $? -eq 0 ]; then
        echo "Remediation: ForwardToSyslog configuration removed successfully and service restarted."
    else
        echo "Error: Failed to remove ForwardToSyslog configuration or restart the service."
    fi
}

# Running the audit
audit_journald_rsyslog
