#!/bin/bash

# Desired audit rules for user emulation
DESIRED_RULES=(
    "-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
    "-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
)

# Function to audit the on-disk rules
audit_on_disk_rules() {
    echo "Auditing on-disk rules..."
    
    # Check the on-disk configuration
    local audit_rules
    audit_rules=$(awk '/^ *-a *always,exit/ && / -F *arch=b[2346]{2}/ && (/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) && (/ -C *euid!=uid/ || / -C *uid!=euid/) && / -S *execve/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules)
    
    # Compare with desired rules
    for desired_rule in "${DESIRED_RULES[@]}"; do
        if ! echo "$audit_rules" | grep -qF "$desired_rule"; then
            echo "Audit Failed: On-disk rule not found: $desired_rule"
            return 1  # Audit failed
        fi
    done

    echo "On-disk rules audit passed."
    return 0  # Audit passed
}

# Function to audit the currently loaded rules
audit_loaded_rules() {
    echo "Auditing currently loaded rules..."
    
    # Check the loaded configuration
    local loaded_rules
    loaded_rules=$(auditctl -l | awk '/^ *-a *always,exit/ && / -F *arch=b[2346]{2}/ && (/ -F *auid!=unset/ || / -F *auid!=-1/ || / -F *auid!=4294967295/) && (/ -C *euid!=uid/ || / -C *uid!=euid/) && / -S *execve/ && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)')
    
    # Compare with desired rules
    for desired_rule in "${DESIRED_RULES[@]}"; do
        if ! echo "$loaded_rules" | grep -qF "$desired_rule"; then
            echo "Audit Failed: Loaded rule not found: $desired_rule"
            return 1  # Audit failed
        fi
    done

    echo "Loaded rules audit passed."
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

    # Create or edit the rules file
    local rules_file="/etc/audit/rules.d/50-user_emulation.rules"
    {
        printf "# Audit rules for monitoring user emulation changes\n"
        for rule in "${DESIRED_RULES[@]}"; do
            printf "%s\n" "$rule"
        done
    } > "$rules_file"

    # Load the rules into the active configuration
    augenrules --load

    # Check if a reboot is required
    if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
        echo "Reboot required to load rules."
    else
        echo "Remediation applied: audit rules updated and loaded."
    fi
}

# Main script execution
if audit_on_disk_rules && audit_loaded_rules; then
    # Audit passed
    echo "Audit configuration for user emulation is correct."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
