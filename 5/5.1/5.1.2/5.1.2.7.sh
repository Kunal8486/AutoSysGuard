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

# Function to check for remote logging configuration
check_remote_logging() {
    echo "Checking for remote logging configuration..."
    if grep -q '$ModLoad imtcp' /etc/rsyslog.conf /etc/rsyslog.d/*.conf; then
        echo "Remote logging configuration found: $ModLoad imtcp"
        return 1
    fi
    if grep -q '$InputTCPServerRun' /etc/rsyslog.conf /etc/rsyslog.d/*.conf; then
        echo "Remote logging configuration found: $InputTCPServerRun"
        return 1
    fi
    if grep -qP -- '^\h*module\(load="imtcp"\)' /etc/rsyslog.conf /etc/rsyslog.d/*.conf; then
        echo "Remote logging configuration found: module(load=\"imtcp\")"
        return 1
    fi
    if grep -qP -- '^\h*input\(type="imtcp" port="514"\)' /etc/rsyslog.conf /etc/rsyslog.d/*.conf; then
        echo "Remote logging configuration found: input(type=\"imtcp\" port=\"514\")"
        return 1
    fi
    echo "No remote logging configuration found."
    return 0
}

# Function to remove remote logging configuration
remove_remote_logging_configuration() {
    echo "Removing remote logging configuration..."
    sed -i '/$ModLoad imtcp/d' /etc/rsyslog.conf
    sed -i '/$InputTCPServerRun/d' /etc/rsyslog.conf
    sed -i '/module(load="imtcp")/d' /etc/rsyslog.conf
    sed -i '/input(type="imtcp" port="514")/d' /etc/rsyslog.conf
    sed -i '/$ModLoad imtcp/d' /etc/rsyslog.d/*.conf
    sed -i '/$InputTCPServerRun/d' /etc/rsyslog.d/*.conf
    sed -i '/module(load="imtcp")/d' /etc/rsyslog.d/*.conf
    sed -i '/input(type="imtcp" port="514")/d' /etc/rsyslog.d/*.conf
    
    # Restart rsyslog service
    systemctl restart rsyslog
    check_command "Failed to restart rsyslog service"
    echo "Remote logging configuration removed and rsyslog service restarted."
}

# Main script execution
echo "Checking rsyslog configuration for remote logging..."

# Display current configuration
display_current_configuration

# Check for existing remote logging configuration
check_remote_logging
if [ $? -ne 0 ]; then
    # If remote logging is found, prompt for removal
    read -p "Remote logging configuration found. Do you want to remove it? (y/n): " remove_choice
    if [[ "$remove_choice" == "y" || "$remove_choice" == "Y" ]]; then
        remove_remote_logging_configuration
    else
        echo "No changes made to the rsyslog configuration."
    fi
else
    echo "No changes needed."
fi

echo "Script execution completed."
