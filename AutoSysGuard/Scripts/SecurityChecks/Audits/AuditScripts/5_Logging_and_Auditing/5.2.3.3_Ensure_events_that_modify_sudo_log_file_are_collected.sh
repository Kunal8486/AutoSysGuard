#!/bin/bash

# Function to get the sudo log file path from the sudoers configuration
get_sudo_log_file() {
    grep -r "logfile" /etc/sudoers* | sed -e 's/.*logfile=//;s/,? .*//' -e 's/"//g'
}

# Desired audit rule for the sudo log file
DESIRED_RULE="-w /var/log/sudo.log -p wa -k sudo_log_file"

# Function to audit the on-disk rules
audit_on_disk_rules() {
    echo "Auditing on-disk rules..."
    
    SUDO_LOG_FILE_ESCAPED=$(get_sudo_log_file | sed 's|/|\\/|g')
    
    if [ -n "${SUDO_LOG_FILE_ESCAPED}" ]; then
        local audit_rules
        audit_rules=$(awk "/^ *-w/ && /${SUDO_LOG_FILE_ESCAPED}/ && / -p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)" /etc/audit/rules.d/*.rules)
        
        # Compare with desired rule
        if ! echo "$audit_rules" | grep -qF "$DESIRED_RULE"; then
            echo "Audit Failed: On-disk rule for sudo log file not found."
            return 1  # Audit failed
        fi
        
        echo "On-disk rules audit passed."
        return 0  # Audit passed
    else
        echo "ERROR: Variable 'SUDO_LOG_FILE_ESCAPED' is unset."
        return 1  # Audit failed
    fi
}

# Function to audit the currently loaded rules
audit_loaded_rules() {
    echo "Auditing currently loaded rules..."
    
    SUDO_LOG_FILE_ESCAPED=$(get_sudo_log_file | sed 's|/|\\/|g')

    if [ -n "${SUDO_LOG_FILE_ESCAPED}" ]; then
        local loaded_rules
        loaded_rules=$(auditctl -l | awk "/^ *-w/ && /${SUDO_LOG_FILE_ESCAPED}/ && / -p *wa/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)")
        
        # Compare with desired rule
        if ! echo "$loaded_rules" | grep -qF "$DESIRED_RULE"; then
            echo "Audit Failed: Loaded rule for sudo log file not found."
            return 1  # Audit failed
        fi
        
        echo "Loaded rules audit passed."
        return 0  # Audit passed
    else
        echo "ERROR: Variable 'SUDO_LOG_FILE_ESCAPED' is unset."
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

    # Create or edit the rules file
    local rules_file="/etc/audit/rules.d/50-sudo.rules"
    SUDO_LOG_FILE=$(get_sudo_log_file)
    
    if [ -n "${SUDO_LOG_FILE}" ]; then
        {
            printf "# Audit rules for monitoring modifications to the sudo log file\n"
            printf "-w ${SUDO_LOG_FILE} -p wa -k sudo_log_file\n"
        } > "$rules_file"

        # Load the rules into the active configuration
        augenrules --load

        # Check if a reboot is required
        if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
            echo "Reboot required to load rules."
        else
            echo "Remediation applied: audit rules updated and loaded."
        fi
    else
        echo "ERROR: Variable 'SUDO_LOG_FILE' is unset. Remediation not applied."
    fi
}

# Main script execution
if audit_on_disk_rules && audit_loaded_rules; then
    # Audit passed
    echo "Audit configuration for sudo log file is correct."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
