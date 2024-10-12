#!/bin/bash

# Function to audit if systemd-journal-upload.service is enabled
audit_systemd_journal_remote_enabled() {
    echo "Auditing systemd-journal-upload.service..."

    # Checking if the service is enabled
    service_status=$(systemctl is-enabled systemd-journal-upload.service 2>/dev/null)

    if [[ "$service_status" == "enabled" ]]; then
        echo "Audit: systemd-journal-upload.service is enabled."
    else
        echo "Audit: systemd-journal-upload.service is not enabled."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to enable the service
    read -p "Do you want to enable systemd-journal-upload.service? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_systemd_journal_remote
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to enable systemd-journal-upload.service
remediate_systemd_journal_remote() {
    echo "Remediation: Enabling systemd-journal-upload.service..."
    sudo systemctl --now enable systemd-journal-upload.service

    if [ $? -eq 0 ]; then
        echo "Remediation: systemd-journal-upload.service enabled successfully."
    else
        echo "Error: Failed to enable systemd-journal-upload.service."
    fi
}

# Running the audit
audit_systemd_journal_remote_enabled
