#!/bin/bash

# Title: Enterprise Compliance Checker for Security Settings
# Author: Kunal Kumar
# Version: 2.0
# Date: 2024-10-14
# Description: This script checks system settings for compliance with security best practices (CIS, NIST, etc.), and generates detailed reports with remediation suggestions.

# Log file location
LOG_FILE="/var/log/compliance_audit.log"
REPORT_FILE="compliance_report.txt"

# Function to log actions
log_action() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to display the main menu
show_main_menu() {
    choice=$(zenity --list --title="Enterprise Compliance Checker" \
                    --column="Select Action" \
                    "Check Password Policies" \
                    "Check User Account Configurations" \
                    "Check File Permissions" \
                    "Check Firewall Settings" \
                    "Check for Security Updates" \
                    "Generate Full Compliance Report" \
                    "View Audit Log" \
                    "Exit")

    case $choice in
        "Check Password Policies")
            check_password_policies
            ;;
        "Check User Account Configurations")
            check_user_accounts
            ;;
        "Check File Permissions")
            check_file_permissions
            ;;
        "Check Firewall Settings")
            check_firewall_settings
            ;;
        "Check for Security Updates")
            check_security_updates
            ;;
        "Generate Full Compliance Report")
            generate_compliance_report
            ;;
        "View Audit Log")
            view_audit_log
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --text="Invalid selection."
            exit 1
            ;;
    esac
}

# Check password policies
check_password_policies() {
    result="Password Policy Check:\n"

    # Check if password expiration is enabled
    expire_status=$(grep -E "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
    if [[ "$expire_status" -le 90 ]]; then
        result+="PASS_MAX_DAYS is set to $expire_status (Compliant: <= 90 days)\n"
    else
        result+="PASS_MAX_DAYS is set to $expire_status (Non-compliant)\n"
    fi

    # Check password complexity (via PAM)
    pam_status=$(grep "pam_pwquality.so" /etc/pam.d/common-password)
    if [[ "$pam_status" =~ "minlen=12" ]] && [[ "$pam_status" =~ "ucredit=-1" ]] && [[ "$pam_status" =~ "lcredit=-1" ]]; then
        result+="Password complexity (minlen=12, ucredit=-1, lcredit=-1) is compliant.\n"
    else
        result+="Password complexity settings are not compliant.\n"
    fi

    log_action "Password policy check completed."
    zenity --info --title="Password Policies Compliance" --text="$result"
}

# Check user account configurations
check_user_accounts() {
    result="User Account Configuration Check:\n"

    # Check if any user has UID 0 (besides root)
    non_root_uid0=$(awk -F: '($3 == 0) && ($1 != "root") {print $1}' /etc/passwd)
    if [[ -z "$non_root_uid0" ]]; then
        result+="No non-root user has UID 0 (Compliant)\n"
    else
        result+="Non-root user(s) with UID 0: $non_root_uid0 (Non-compliant)\n"
    fi

    # Check for empty password fields
    empty_password_users=$(awk -F: '($2 == "") {print $1}' /etc/shadow)
    if [[ -z "$empty_password_users" ]]; then
        result+="No users have empty password fields (Compliant)\n"
    else
        result+="User(s) with empty password fields: $empty_password_users (Non-compliant)\n"
    fi

    log_action "User account check completed."
    zenity --info --title="User Account Configurations Compliance" --text="$result"
}

# Check file permissions on critical system files
check_file_permissions() {
    result="File Permissions Check:\n"

    # Check permissions of /etc/passwd
    passwd_perms=$(stat -c "%a" /etc/passwd)
    if [[ "$passwd_perms" -eq 644 ]]; then
        result+="/etc/passwd permissions are correct (644).\n"
    else
        result+="/etc/passwd permissions are incorrect (Non-compliant).\n"
    fi

    # Check permissions of /etc/shadow
    shadow_perms=$(stat -c "%a" /etc/shadow)
    if [[ "$shadow_perms" -eq 600 ]]; then
        result+="/etc/shadow permissions are correct (600).\n"
    else
        result+="/etc/shadow permissions are incorrect (Non-compliant).\n"
    fi

    log_action "File permission check completed."
    zenity --info --title="File Permissions Compliance" --text="$result"
}

# Check firewall settings
check_firewall_settings() {
    result="Firewall Configuration Check:\n"

    # Check if UFW (Uncomplicated Firewall) is active
    ufw_status=$(ufw status | grep "Status: active")
    if [[ -n "$ufw_status" ]]; then
        result+="UFW firewall is active (Compliant)\n"
    else
        result+="UFW firewall is not active (Non-compliant)\n"
    fi

    log_action "Firewall settings check completed."
    zenity --info --title="Firewall Settings Compliance" --text="$result"
}

# Check for security updates
check_security_updates() {
    result="Security Update Check:\n"

    # Check if there are any security updates available
    updates=$(apt list --upgradable 2>/dev/null | grep -i "security")
    if [[ -n "$updates" ]]; then
        result+="Security updates available:\n$updates\n"
    else
        result+="No security updates available (Compliant).\n"
    fi

    log_action "Security updates check completed."
    zenity --info --title="Security Updates" --text="$result"
}

# Generate a full compliance report
generate_compliance_report() {
    report="Full Compliance Report:\n"
    
    # Password policies
    report+="\nPassword Policies:\n"
    expire_status=$(grep -E "^PASS_MAX_DAYS" /etc/login.defs | awk '{print $2}')
    if [[ "$expire_status" -le 90 ]]; then
        report+="PASS_MAX_DAYS is set to $expire_status (Compliant: <= 90 days)\n"
    else
        report+="PASS_MAX_DAYS is set to $expire_status (Non-compliant)\n"
    fi
    pam_status=$(grep "pam_pwquality.so" /etc/pam.d/common-password)
    if [[ "$pam_status" =~ "minlen=12" ]] && [[ "$pam_status" =~ "ucredit=-1" ]] && [[ "$pam_status" =~ "lcredit=-1" ]]; then
        report+="Password complexity (minlen=12, ucredit=-1, lcredit=-1) is compliant.\n"
    else
        report+="Password complexity settings are not compliant.\n"
    fi
    
    # User accounts
    report+="\nUser Account Configurations:\n"
    non_root_uid0=$(awk -F: '($3 == 0) && ($1 != "root") {print $1}' /etc/passwd)
    if [[ -z "$non_root_uid0" ]]; then
        report+="No non-root user has UID 0 (Compliant)\n"
    else
        report+="Non-root user(s) with UID 0: $non_root_uid0 (Non-compliant)\n"
    fi
    empty_password_users=$(awk -F: '($2 == "") {print $1}' /etc/shadow)
    if [[ -z "$empty_password_users" ]]; then
        report+="No users have empty password fields (Compliant)\n"
    else
        report+="User(s) with empty password fields: $empty_password_users (Non-compliant)\n"
    fi

    # File permissions
    report+="\nFile Permissions:\n"
    passwd_perms=$(stat -c "%a" /etc/passwd)
    if [[ "$passwd_perms" -eq 644 ]]; then
        report+="/etc/passwd permissions are correct (644).\n"
    else
        report+="/etc/passwd permissions are incorrect (Non-compliant).\n"
    fi
    shadow_perms=$(stat -c "%a" /etc/shadow)
    if [[ "$shadow_perms" -eq 600 ]]; then
        report+="/etc/shadow permissions are correct (600).\n"
    else
        report+="/etc/shadow permissions are incorrect (Non-compliant).\n"
    fi

    # Firewall settings
    report+="\nFirewall Settings:\n"
    ufw_status=$(ufw status | grep "Status: active")
    if [[ -n "$ufw_status" ]]; then
        report+="UFW firewall is active (Compliant)\n"
    else
        report+="UFW firewall is not active (Non-compliant)\n"
    fi

    # Security updates
    report+="\nSecurity Updates:\n"
    updates=$(apt list --upgradable 2>/dev/null | grep -i "security")
    if [[ -n "$updates" ]]; then
        report+="Security updates available:\n$updates\n"
    else
        report+="No security updates available (Compliant).\n"
    fi

    # Save report to file
    echo -e "$report" > "$REPORT_FILE"
    log_action "Full compliance report generated."
    zenity --info --title="Compliance Report" --text="Full report saved to $REPORT_FILE"
}

# View audit log
view_audit_log() {
    zenity --text-info --title="Audit Log" --filename="$LOG_FILE"
}

# Initialize the log
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
fi

# Show the main menu
show_main_menu
