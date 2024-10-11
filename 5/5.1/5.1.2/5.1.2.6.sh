#!/bin/bash

# Function to check if a command succeeded
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Function to display the current rsyslog configuration
display_current_configuration() {
    echo "Current rsyslog configuration:"
    cat /etc/rsyslog.conf
    echo
    echo "Additional configuration files:"
    cat /etc/rsyslog.d/*.conf
    echo
}

# Function to check for existing remote logging configuration
check_remote_logging() {
    echo "Checking for remote logging configuration..."
    if grep -qE '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf; then
        echo "Remote logging configuration found."
    else
        echo "No remote logging configuration found."
    fi
    echo
}

# Function to update rsyslog configuration for remote logging
update_remote_logging_configuration() {
    echo "Updating rsyslog configuration to send logs to a remote host..."
    {
        echo "*.* action(type=\"omfwd\" target=\"192.168.2.100\" port=\"514\" protocol=\"tcp\""
        echo "action.resumeRetryCount=\"100\""
        echo "queue.type=\"LinkedList\" queue.size=\"1000\")"
    } >> /etc/rsyslog.conf

    # Restart rsyslog service
    systemctl restart rsyslog
    check_command "Failed to restart rsyslog service"
    echo "rsyslog configuration updated to send logs to remote host and service restarted."
}

# Main script execution
echo "Checking rsyslog remote logging configuration..."

# Display current configuration
display_current_configuration

# Check for existing remote logging configuration
check_remote_logging

# Prompt to update configuration
read -p "Do you want to update the rsyslog configuration to send logs to a remote host? (y/n): " update_choice
if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
    update_remote_logging_configuration
else
    echo "No changes made to the rsyslog configuration."
fi

echo "Script execution completed."
