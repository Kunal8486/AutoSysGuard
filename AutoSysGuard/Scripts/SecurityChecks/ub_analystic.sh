#!/bin/bash

# Title: User Behavior Analytics (UBA)
# Author: Kunal Kumar
# Version: 1.0
# Date: 2024-10-14
# Description: This script monitors user activity (logins, commands, and file access) and generates alerts for anomalous behavior.

LOG_FILE="/var/log/uba_audit.log"
ALERT_FILE="./log/uba_alerts.txt"

# Function to log actions
log_action() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to detect failed login attempts
check_failed_logins() {
    result="Failed Login Attempts:\n"
    failed_attempts=$(grep "Failed password" /var/log/auth.log | tail -n 10)
    if [[ -n "$failed_attempts" ]]; then
        result+="Recent failed login attempts detected:\n$failed_attempts\n"
        echo "$result" >> "$ALERT_FILE"
    else
        result+="No failed login attempts detected.\n"
    fi
    log_action "Checked failed login attempts."
    echo -e "$result"
}

# Function to detect successful login sessions
check_successful_logins() {
    result="Successful Login Sessions:\n"
    recent_logins=$(last -n 10)
    if [[ -n "$recent_logins" ]]; then
        result+="Recent successful login sessions:\n$recent_logins\n"
    else
        result+="No recent successful logins detected.\n"
    fi
    log_action "Checked successful login sessions."
    echo -e "$result"
}

# Function to monitor command history
check_command_history() {
    result="Suspicious Commands Detected in History:\n"
    for user in $(cut -d: -f1 /etc/passwd); do
        if [[ -f /home/$user/.bash_history ]]; then
            history_file="/home/$user/.bash_history"
        elif [[ -f /root/.bash_history && $user == "root" ]]; then
            history_file="/root/.bash_history"
        else
            continue
        fi

        # Check for potentially suspicious commands (e.g., sudo, passwd, rm -rf)
        suspicious_commands=$(grep -E "(sudo|passwd|rm -rf|chmod 777)" "$history_file")
        if [[ -n "$suspicious_commands" ]]; then
            result+="User $user has executed suspicious commands:\n$suspicious_commands\n"
            echo "$result" >> "$ALERT_FILE"
        fi
    done
    log_action "Checked command history for suspicious commands."
    echo -e "$result"
}

# Function to monitor sensitive file access (requires auditd)
monitor_file_access() {
    result="Sensitive File Access:\n"
    sensitive_files="/etc/passwd /etc/shadow /etc/sudoers"
    
    # Check audit log for access to sensitive files
    for file in $sensitive_files; do
        access_attempts=$(ausearch -f "$file" --interpret | tail -n 5)
        if [[ -n "$access_attempts" ]]; then
            result+="Recent access to $file:\n$access_attempts\n"
            echo "$result" >> "$ALERT_FILE"
        else
            result+="No recent access to $file.\n"
        fi
    done
    log_action "Monitored sensitive file access."
    echo -e "$result"
}

# Function to generate report of anomalies
generate_report() {
    echo "Generating UBA Report..."
    echo -e "\n=== User Behavior Analytics Report ===\n" > "$ALERT_FILE"
    
    # Check failed logins
    check_failed_logins >> "$ALERT_FILE"
    
    # Check successful logins
    check_successful_logins >> "$ALERT_FILE"

    # Check command history
    check_command_history >> "$ALERT_FILE"
    
    # Monitor file access
    monitor_file_access >> "$ALERT_FILE"
    
    log_action "UBA report generated."
    zenity --info --title="UBA Report" --text="UBA Report generated: $ALERT_FILE"
}

# Function to display the main menu
show_main_menu() {
    choice=$(zenity --list --title="User Behavior Analytics" \
                    --column="Select Action" \
                    "Check Failed Logins" \
                    "Check Successful Logins" \
                    "Check Command History" \
                    "Monitor File Access" \
                    "Generate Full UBA Report" \
                    "View UBA Log" \
                    "Exit")

    case $choice in
        "Check Failed Logins")
            check_failed_logins
            ;;
        "Check Successful Logins")
            check_successful_logins
            ;;
        "Check Command History")
            check_command_history
            ;;
        "Monitor File Access")
            monitor_file_access
            ;;
        "Generate Full UBA Report")
            generate_report
            ;;
        "View UBA Log")
            zenity --text-info --title="UBA Log" --filename="$LOG_FILE"
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

# Initialize the log if it doesn't exist
if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    log_action "UBA script started."
fi

# Show the main menu
show_main_menu
