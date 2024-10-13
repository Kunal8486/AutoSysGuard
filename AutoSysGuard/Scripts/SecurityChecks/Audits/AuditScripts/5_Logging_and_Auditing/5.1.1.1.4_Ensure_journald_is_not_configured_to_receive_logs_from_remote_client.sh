#!/bin/bash

# Function to check if systemd-journal-remote.socket is enabled
check_journal_remote_socket() {
    echo "Checking the status of systemd-journal-remote.socket..."

    # Check if the service file exists
    if [[ -f /lib/systemd/system/systemd-journal-remote.socket ]]; then
        # Get the status of the socket
        STATUS=$(systemctl is-enabled systemd-journal-remote.socket 2>/dev/null)

        if [[ "$STATUS" == "disabled" ]]; then
            echo "systemd-journal-remote.socket is disabled."
            return 0  # Audit passed
        else
            echo "systemd-journal-remote.socket is NOT disabled."
            return 1  # Audit failed
        fi
    else
        echo "systemd-journal-remote.socket does not exist. Please install the required package."
        return 2  # Service file not found
    fi
}

# Function to disable systemd-journal-remote.socket
disable_journal_remote_socket() {
    echo "Disabling systemd-journal-remote.socket..."

    # Attempt to disable the socket
    systemctl --now disable systemd-journal-remote.socket
    if [[ $? -eq 0 ]]; then
        echo "systemd-journal-remote.socket has been disabled."
    else
        echo "Failed to disable systemd-journal-remote.socket."
    fi
}

# Main script execution
check_journal_remote_socket
result=$?

if [[ $result -eq 0 ]]; then
    echo "Audit passed. No remediation needed."
elif [[ $result -eq 1 ]]; then
    echo "Audit failed. Would you like to apply remediation? (y/n)"
    read -r RESPONSE

    if [[ "$RESPONSE" == "y" || "$RESPONSE" == "Y" ]]; then
        disable_journal_remote_socket
    else
        echo "No changes made. Exiting."
    fi
else
    echo "To install the required package, please run the following command:"
    echo "sudo apt install systemd-journal-remote"
fi
