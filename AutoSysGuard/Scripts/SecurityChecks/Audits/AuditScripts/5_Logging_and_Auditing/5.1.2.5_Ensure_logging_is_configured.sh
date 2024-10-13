#!/bin/bash

# Function to audit logging configuration
audit_logging_configuration() {
    echo "Auditing logging configuration..."

    # Check if /etc/rsyslog.conf exists
    if [[ ! -f /etc/rsyslog.conf ]]; then
        echo "Audit Failed: /etc/rsyslog.conf file does not exist."
        return 1  # Audit failed
    fi

    # Check for the required logging rules in /etc/rsyslog.conf
    echo "Checking /etc/rsyslog.conf..."
    local config_check=$(grep -E 'auth,authpriv\.\*|mail\.\*|cron\.\*|local[0-7]\.\*' /etc/rsyslog.conf)

    if [[ -z "$config_check" ]]; then
        echo "Audit Failed: Required logging rules not found in /etc/rsyslog.conf."
        return 1  # Audit failed
    fi

    # Check if /etc/rsyslog.d/*.conf files exist and contain rules
    echo "Checking /etc/rsyslog.d/*.conf files..."
    local rules_found=false
    for conf_file in /etc/rsyslog.d/*.conf; do
        if [[ -f $conf_file ]]; then
            if grep -E 'auth,authpriv\.\*|mail\.\*|cron\.\*|local[0-7]\.\*' "$conf_file" &> /dev/null; then
                rules_found=true
                break
            fi
        fi
    done

    if [[ "$rules_found" == false ]]; then
        echo "Audit Failed: Required logging rules not found in /etc/rsyslog.d/*.conf files."
        return 1  # Audit failed
    fi

    # Check if log files exist in /var/log/
    echo "Checking log files in /var/log/..."
    log_check=$(ls -l /var/log/)

    if [[ -z "$log_check" ]]; then
        echo "Audit Failed: No log files found in /var/log/."
        return 1  # Audit failed
    fi

    echo "Audit Passed: Logging configuration is set correctly."
    return 0  # Audit passed
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

    # Add or update logging rules in /etc/rsyslog.conf
    {
        echo "*.emerg :omusrmsg:*"
        echo "auth,authpriv.* /var/log/secure"
        echo "mail.* -/var/log/mail"
        echo "mail.info -/var/log/mail.info"
        echo "mail.warning -/var/log/mail.warn"
        echo "mail.err /var/log/mail.err"
        echo "cron.* /var/log/cron"
        echo "*.=warning;*.=err -/var/log/warn"
        echo "*.crit /var/log/warn"
        echo "*.*;mail.none;news.none -/var/log/messages"
        echo "local0,local1.* -/var/log/localmessages"
        echo "local2,local3.* -/var/log/localmessages"
        echo "local4,local5.* -/var/log/localmessages"
        echo "local6,local7.* -/var/log/localmessages"
    } > /etc/rsyslog.conf

    # Restart the rsyslog service to apply changes
    systemctl restart rsyslog
    echo "Remediation applied: Logging configuration updated and rsyslog service restarted."
    
    # Re-run audit to confirm the changes
    if audit_logging_configuration; then
        echo "Audit Passed: Logging configuration is now correct."
    else
        echo "Audit Failed after remediation. Please check the configuration."
    fi
}

# Main script execution
if audit_logging_configuration; then
    # Audit passed
    echo "Logging configuration is set correctly."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
