#!/bin/bash

# Function to audit if systemd-journal-remote.socket is disabled
audit_journal_remote_socket() {
    echo "Auditing systemd-journal-remote.socket..."

    # Checking if the socket is disabled
    socket_status=$(systemctl is-enabled systemd-journal-remote.socket 2>/dev/null)

    if [[ "$socket_status" == "disabled" ]]; then
        echo "Audit: systemd-journal-remote.socket is disabled."
    else
        echo "Audit: systemd-journal-remote.socket is enabled."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to disable the socket
    read -p "Do you want to disable systemd-journal-remote.socket? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_journal_remote_socket
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to disable systemd-journal-remote.socket
remediate_journal_remote_socket() {
    echo "Remediation: Disabling systemd-journal-remote.socket..."
    sudo systemctl --now disable systemd-journal-remote.socket

    if [ $? -eq 0 ]; then
        echo "Remediation: systemd-journal-remote.socket disabled successfully."
    else
        echo "Error: Failed to disable systemd-journal-remote.socket."
    fi
}

# Running the audit
audit_journal_remote_socket
