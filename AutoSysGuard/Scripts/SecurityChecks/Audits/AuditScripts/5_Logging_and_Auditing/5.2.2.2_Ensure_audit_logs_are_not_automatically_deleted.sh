#!/bin/bash

# Configuration file
auditd_config_file="/etc/audit/auditd.conf"
desired_value="keep_logs"

# Check current max_log_file_action setting
current_action=$(grep 'max_log_file_action' "$auditd_config_file")

if [ -n "$current_action" ]; then
    current_value=$(echo "$current_action" | cut -d '=' -f2 | xargs)
    echo "Current max_log_file_action is set to: $current_value"
    
    # Check if the current setting is already the desired value
    if [ "$current_value" == "$desired_value" ]; then
        echo "max_log_file_action is already set to keep_logs. No changes are necessary."
        exit 0
    else
        # Prompt user for confirmation to change the value
        read -p "Do you want to set max_log_file_action to keep_logs? (y/n): " user_choice
        if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
            # Update max_log_file_action in auditd.conf
            sed -i "s/^max_log_file_action\s*=\s*\w\+$/max_log_file_action = $desired_value/" "$auditd_config_file"
            echo "max_log_file_action has been updated to keep_logs in /etc/audit/auditd.conf."
        else
            echo "max_log_file_action will not be changed."
        fi
    fi
else
    echo "max_log_file_action is not set. Setting it to keep_logs."
    read -p "Do you want to proceed? (y/n): " proceed_choice
    if [[ "$proceed_choice" == "y" || "$proceed_choice" == "Y" ]]; then
        # Set max_log_file_action to keep_logs
        echo "max_log_file_action = $desired_value" >> "$auditd_config_file"
        echo "max_log_file_action has been added to /etc/audit/auditd.conf."
    else
        echo "max_log_file_action will not be set."
    fi
fi
