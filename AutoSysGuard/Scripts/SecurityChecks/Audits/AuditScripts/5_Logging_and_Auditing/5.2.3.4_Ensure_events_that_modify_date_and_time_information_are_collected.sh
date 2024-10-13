#!/bin/bash

# Define the audit rules
AUDIT_RULES_64="\
-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change
-w /etc/localtime -p wa -k time-change"

AUDIT_RULES_32="\
-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime,stime -k time-change"

# Function to check current audit rules
check_audit_rules() {
    echo "Checking current audit rules..."

    # Check for 64-bit rules
    if ! auditctl -l | awk '/^ *-a *always,exit/ && /-F *arch=b64/ && /-S/ && (/adjtimex/ || /settimeofday/ || /clock_settime/) { exit 0 } END { exit 1 }'; then
        echo "64-bit audit rule is missing."
        NEED_REMEDIATION=true
    else
        echo "64-bit audit rule is present."
    fi

    # Check for 32-bit rules
    if ! auditctl -l | awk '/^ *-a *always,exit/ && /-F *arch=b32/ && /-S/ && (/adjtimex/ || /settimeofday/ || /clock_settime/) { exit 0 } END { exit 1 }'; then
        echo "32-bit audit rule is missing."
        NEED_REMEDIATION=true
    else
        echo "32-bit audit rule is present."
    fi

    # Check for /etc/localtime rule
    if ! auditctl -l | awk '/^ *-w/ && /\/etc\/localtime/ && /-p *wa/ { exit 0 } END { exit 1 }'; then
        echo "/etc/localtime rule is missing."
        NEED_REMEDIATION=true
    else
        echo "/etc/localtime rule is present."
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Create the audit rules file
    echo "$AUDIT_RULES_64" > /etc/audit/rules.d/50-time-change.rules
    echo "$AUDIT_RULES_32" >> /etc/audit/rules.d/50-time-change.rules

    # Load the audit rules
    augenrules --load

    # Check if reboot is required
    if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
        echo "Reboot required to load rules."
    else
        echo "Audit rules successfully applied without reboot."
    fi
}

# Main script execution
NEED_REMEDIATION=false

# Check current audit rules
check_audit_rules

# If remediation is needed, prompt user
if [ "$NEED_REMEDIATION" = true ]; then
    read -p "Do you want to apply remediation? (y/n): " choice
    case "$choice" in
        y|Y ) apply_remediation ;;
        n|N ) echo "No remediation applied." ;;
        * ) echo "Invalid choice. Exiting." ;;
    esac
else
    echo "All required audit rules are already in place."
fi
