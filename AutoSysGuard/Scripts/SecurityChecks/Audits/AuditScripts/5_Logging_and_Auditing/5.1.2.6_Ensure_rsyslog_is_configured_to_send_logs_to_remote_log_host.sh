#!/bin/bash

# Function to audit remote logging configuration
audit_remote_logging() {
    echo "Auditing remote logging configuration..."

    # Check if /etc/rsyslog.conf exists
    if [[ ! -f /etc/rsyslog.conf ]]; then
        echo "Audit Failed: /etc/rsyslog.conf file does not exist."
        return 1  # Audit failed
    fi

    # Check for old format logging to remote host
    echo "Checking old format in /etc/rsyslog.conf and /etc/rsyslog.d/*.conf..."
    local old_format_check=$(grep "^*.*[^I][^I]*@" /etc/rsyslog.conf /etc/rsyslog.d/*.conf)

    if [[ -n "$old_format_check" && "$old_format_check" == *"@@loghost.example.com"* ]]; then
        echo "Audit Passed: Remote logging configured using old format."
        return 0  # Audit passed
    fi

    # Check for new format logging to remote host
    echo "Checking new format in /etc/rsyslog.conf and /etc/rsyslog.d/*.conf..."
    local new_format_check=$(grep -E '^\s*([^#]+\s+)?action\(([^#]+\s+)?\btarget=\"?[^#"]+\"?\b' /etc/rsyslog.conf /etc/rsyslog.d/*.conf)

    if [[ -n "$new_format_check" && "$new_format_check" == *"target=\"loghost.example.com\""* ]]; then
        echo "Audit Passed: Remote logging configured using new format."
        return 0  # Audit passed
    fi

    echo "Audit Failed: Remote logging is not configured correctly."
    return 1  # Audit failed
}

# Function to ask user for remediation
ask_for_remediation() {
    read -p "Do you want to apply remediation? (y/n): " answer
    case $answer in
        [Yy]* ) apply_remediation ;;
        [Nn]* ) echo "No remediation applied." ;;
        * ) echo "Invalid input. No remediation applied." ;;
    esac
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Backup existing rsyslog configuration
    cp /etc/rsyslog.conf /etc/rsyslog.conf.bak

    # Add remote logging configuration
    {
        echo "*.* action(type=\"omfwd\" target=\"192.168.2.100\" port=\"514\" protocol=\"tcp\""
        echo " action.resumeRetryCount=\"100\" queue.type=\"LinkedList\" queue.size=\"1000\")"
    } >> /etc/rsyslog.conf

    # Restart the rsyslog service to apply changes
    systemctl restart rsyslog
    echo "Remediation applied: Remote logging configuration updated and rsyslog service restarted."
    
    # Re-run audit to confirm the changes
    if audit_remote_logging; then
        echo "Audit Passed: Remote logging configuration is now correct."
    else
        echo "Audit Failed after remediation. Please check the configuration."
    fi
}

# Main script execution
if audit_remote_logging; then
    # Audit passed
    echo "Remote logging configuration is set correctly."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
