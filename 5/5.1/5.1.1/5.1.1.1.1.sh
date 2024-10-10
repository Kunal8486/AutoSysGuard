#!/bin/bash

# Function to audit if systemd-journal-remote is installed
audit_systemd_journal_remote() {
    # Running dpkg-query to check the package status
    dpkg-query -W -f='${binary:Package}\t${Status}\n' systemd-journal-remote | grep -q "install ok installed"

    if [ $? -eq 0 ]; then
        echo "Audit: systemd-journal-remote is already installed."
    else
        echo "Audit: systemd-journal-remote is not installed."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to apply the remediation
    read -p "Do you want to install systemd-journal-remote? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_systemd_journal_remote
    else
        echo "Remediation not applied."
    fi
}

# Function to remediate by installing systemd-journal-remote
remediate_systemd_journal_remote() {
    echo "Remediation: Installing systemd-journal-remote..."
    sudo apt update && sudo apt install -y systemd-journal-remote

    if [ $? -eq 0 ]; then
        echo "Remediation: systemd-journal-remote installed successfully."
    else
        echo "Error: Failed to install systemd-journal-remote."
    fi
}

# Running the audit
audit_systemd_journal_remote
