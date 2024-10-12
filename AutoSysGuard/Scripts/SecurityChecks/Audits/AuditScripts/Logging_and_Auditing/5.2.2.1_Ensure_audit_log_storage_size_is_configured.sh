#!/bin/bash

# Set default and recommended maximum log file size (in MB)
default_max_log_file=8
grub_config_file="/etc/audit/auditd.conf"

# Check current max_log_file setting
current_max_log_file=$(grep -Po '^\h*max_log_file\h*=\h*\d+' "$grub_config_file")

if [ -n "$current_max_log_file" ]; then
    current_value=$(echo "$current_max_log_file" | cut -d '=' -f2 | xargs)
    echo "Current max_log_file size is set to: $current_value MB"
    
    # Prompt user for new size if current value is not sufficient
    read -p "Do you want to set a new max_log_file size? (y/n): " user_choice
    if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
        read -p "Enter the new max_log_file size in MB (recommended size > $default_max_log_file): " new_value
        if [[ "$new_value" =~ ^[0-9]+$ ]]; then
            # Update max_log_file in auditd.conf
            sed -i "s/^max_log_file\s*=\s*\d\+$/max_log_file = $new_value/" "$grub_config_file"
            echo "max_log_file has been updated to $new_value MB in /etc/audit/auditd.conf."
        else
            echo "Invalid input. Please enter a numeric value."
        fi
    else
        echo "max_log_file will not be changed."
    fi
else
    echo "max_log_file is not set. Setting it to the default value of $default_max_log_file MB."
    read -p "Do you want to proceed? (y/n): " proceed_choice
    if [[ "$proceed_choice" == "y" || "$proceed_choice" == "Y" ]]; then
        # Set max_log_file to the default value
        echo "max_log_file = $default_max_log_file" >> "$grub_config_file"
        echo "max_log_file has been added to /etc/audit/auditd.conf."
    else
        echo "max_log_file will not be set."
    fi
fi
