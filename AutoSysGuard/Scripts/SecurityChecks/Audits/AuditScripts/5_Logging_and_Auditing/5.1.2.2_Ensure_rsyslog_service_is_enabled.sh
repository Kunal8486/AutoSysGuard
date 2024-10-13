#!/bin/bash

# Function to audit rsyslog service status
audit_rsyslog_service() {
    echo "Auditing rsyslog service status..."

    # Check if rsyslog service is enabled
    if systemctl is-enabled rsyslog &>/dev/null; then
        if [[ $(systemctl is-enabled rsyslog) == "enabled" ]]; then
            echo "Audit: rsyslog service is enabled."
        else
            echo "Audit: rsyslog service is not enabled."
            prompt_enable_service
        fi
    else
        echo "Audit: rsyslog service does not exist."
    fi
}

# Function to prompt the user for enabling the service
prompt_enable_service() {
    read -p "Do you want to enable the rsyslog service? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        enable_rsyslog_service
    else
        echo "You chose not to enable the rsyslog service. Exiting."
    fi
}

# Function to enable rsyslog service
enable_rsyslog_service() {
    echo "Enabling rsyslog service..."

    # Enable and start rsyslog service
    sudo systemctl --now enable rsyslog

    if [ $? -eq 0 ]; then
        echo "Service enabled successfully: rsyslog service is now enabled."
    else
        echo "Error: Failed to enable rsyslog service."
    fi
}

# Run the audit
audit_rsyslog_service
