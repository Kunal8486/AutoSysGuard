#!/bin/bash

# Function to check if a command succeeded
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Function to display the logging configuration
display_logging_configuration() {
    echo "Current rsyslog configuration:"
    cat /etc/rsyslog.conf
    echo
    echo "Additional configuration files:"
    cat /etc/rsyslog.d/*.conf
    echo
}

# Function to check the existence of log files
check_log_files() {
    echo "Current log files in /var/log/:"
    ls -l /var/log/
    echo
}

# Function to update rsyslog configuration
update_rsyslog_configuration() {
    echo "Updating rsyslog configuration..."
    {
        echo "*.emerg                        :omusrmsg:*"
        echo "auth,authpriv.*                /var/log/secure"
        echo "mail.*                          -/var/log/mail"
        echo "mail.info                       -/var/log/mail.info"
        echo "mail.warning                    -/var/log/mail.warn"
        echo "mail.err                        /var/log/mail.err"
        echo "cron.*                          /var/log/cron"
        echo "*.=warning;*.=err              -/var/log/warn"
        echo "*.crit                          /var/log/warn"
        echo "*.*;mail.none;news.none        -/var/log/messages"
        echo "local0,local1.*                -/var/log/localmessages"
        echo "local2,local3.*                -/var/log/localmessages"
        echo "local4,local5.*                -/var/log/localmessages"
        echo "local6,local7.*                -/var/log/localmessages"
    } > /etc/rsyslog.conf

    # Restart rsyslog service
    systemctl restart rsyslog
    check_command "Failed to restart rsyslog service"
    echo "rsyslog configuration updated and service restarted."
}

# Main script execution
echo "Checking rsyslog logging configuration..."

# Display current configuration
display_logging_configuration

# Check log files
check_log_files

# Prompt to update configuration
read -p "Do you want to update the rsyslog configuration? (y/n): " update_choice
if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
    update_rsyslog_configuration
else
    echo "No changes made to the rsyslog configuration."
fi

echo "Script execution completed."
