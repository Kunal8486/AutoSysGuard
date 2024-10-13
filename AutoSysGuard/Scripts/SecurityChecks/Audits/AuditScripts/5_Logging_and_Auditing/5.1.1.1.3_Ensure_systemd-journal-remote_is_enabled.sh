#!/bin/bash

# Function to check if systemd-journal-upload.service is enabled
check_journal_upload_service() {
    echo "Checking the status of systemd-journal-upload.service..."

    # Check if the service file exists
    if [[ -f /lib/systemd/system/systemd-journal-upload.service ]]; then
        # Get the status of the service
        STATUS=$(systemctl is-enabled systemd-journal-upload.service 2>/dev/null)

        if [[ "$STATUS" == "enabled" ]]; then
            echo "systemd-journal-upload.service is enabled."
            return 0  # Audit passed
        else
            echo "systemd-journal-upload.service is NOT enabled."
            return 1  # Audit failed
        fi
    else
        echo "systemd-journal-upload.service does not exist. Please install the required package."
        return 2  # Service file not found
    fi
}

# Function to enable systemd-journal-upload.service
enable_journal_upload_service() {
    echo "Enabling systemd-journal-upload.service..."

    # Attempt to enable the service
    systemctl --now enable systemd-journal-upload.service
    if [[ $? -eq 0 ]]; then
        echo "systemd-journal-upload.service has been enabled."
    else
        echo "Failed to enable systemd-journal-upload.service."
    fi
}

# Main script execution
check_journal_upload_service
result=$?

if [[ $result -eq 0 ]]; then
    echo "Audit passed. No remediation needed."
elif [[ $result -eq 1 ]]; then
    echo "Audit failed. Would you like to apply remediation? (y/n)"
    read -r RESPONSE

    if [[ "$RESPONSE" == "y" || "$RESPONSE" == "Y" ]]; then
        enable_journal_upload_service
    else
        echo "No changes made. Exiting."
    fi
else
    echo "To install the required package, please run the following command:"
    echo "sudo apt install systemd-journal-remote"
fi
