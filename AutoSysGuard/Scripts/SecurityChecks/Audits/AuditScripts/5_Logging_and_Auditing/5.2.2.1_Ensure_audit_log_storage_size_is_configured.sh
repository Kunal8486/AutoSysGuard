#!/bin/bash

# Desired log file size in MB
DESIRED_LOG_FILE_SIZE=8

# Function to audit the max_log_file setting
audit_max_log_file() {
    echo "Auditing audit log storage size..."

    # Check if /etc/audit/auditd.conf exists
    if [[ ! -f /etc/audit/auditd.conf ]]; then
        echo "Audit Failed: /etc/audit/auditd.conf file does not exist."
        return 1  # Audit failed
    fi

    # Check the max_log_file setting
    local current_size=$(grep -Po -- '^\s*max_log_file\s*=\s*\d+\b' /etc/audit/auditd.conf)

    if [[ "$current_size" == "max_log_file = $DESIRED_LOG_FILE_SIZE" ]]; then
        echo "Audit Passed: Current max_log_file size is set to ${DESIRED_LOG_FILE_SIZE}MB."
        return 0  # Audit passed
    else
        echo "Audit Failed: Current max_log_file size is not set to ${DESIRED_LOG_FILE_SIZE}MB."
        return 1  # Audit failed
    fi
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

    # Backup existing auditd configuration
    cp /etc/audit/auditd.conf /etc/audit/auditd.conf.bak

    # Set max_log_file to desired value
    if grep -q '^\s*max_log_file\s*=' /etc/audit/auditd.conf; then
        # Update existing max_log_file entry
        sed -i "s/^\s*max_log_file\s*=.*/max_log_file = $DESIRED_LOG_FILE_SIZE/" /etc/audit/auditd.conf
    else
        # Add max_log_file if not present
        echo "max_log_file = $DESIRED_LOG_FILE_SIZE" >> /etc/audit/auditd.conf
    fi

    # Restart the auditd service to apply changes
    systemctl restart auditd
    echo "Remediation applied: max_log_file set to ${DESIRED_LOG_FILE_SIZE}MB and auditd service restarted."

    # Re-run audit to confirm the changes
    if audit_max_log_file; then
        echo "Audit Passed: max_log_file is now set correctly."
    else
        echo "Audit Failed after remediation. Please check the configuration."
    fi
}

# Main script execution
if audit_max_log_file; then
    # Audit passed
    echo "Audit log storage size is correctly configured."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
