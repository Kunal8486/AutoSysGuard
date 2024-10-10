#!/bin/bash

# Configuration file
auditd_config_file="/etc/audit/auditd.conf"

# Desired values
desired_space_left_action="email"
desired_action_mail_acct="root"
desired_admin_space_left_action="halt"  # You can change this to "single" if preferred

# Check current settings
current_space_left_action=$(grep 'space_left_action' "$auditd_config_file")
current_action_mail_acct=$(grep 'action_mail_acct' "$auditd_config_file")
current_admin_space_left_action=$(grep 'admin_space_left_action' "$auditd_config_file")

# Update space_left_action if not set correctly
if [[ -n "$current_space_left_action" ]]; then
    current_value=$(echo "$current_space_left_action" | cut -d '=' -f2 | xargs)
    if [ "$current_value" != "$desired_space_left_action" ]; then
        echo "Current space_left_action is set to: $current_value"
        read -p "Do you want to change space_left_action to $desired_space_left_action? (y/n): " user_choice
        if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
            sed -i "s/^space_left_action\s*=\s*\w\+$/space_left_action = $desired_space_left_action/" "$auditd_config_file"
            echo "space_left_action has been updated to $desired_space_left_action."
        else
            echo "space_left_action will not be changed."
        fi
    else
        echo "space_left_action is already set to $desired_space_left_action."
    fi
else
    echo "space_left_action is not set. Setting it to $desired_space_left_action."
    read -p "Do you want to proceed? (y/n): " proceed_choice
    if [[ "$proceed_choice" == "y" || "$proceed_choice" == "Y" ]]; then
        echo "space_left_action = $desired_space_left_action" >> "$auditd_config_file"
        echo "space_left_action has been added to $auditd_config_file."
    fi
fi

# Update action_mail_acct if not set correctly
if [[ -n "$current_action_mail_acct" ]]; then
    current_value=$(echo "$current_action_mail_acct" | cut -d '=' -f2 | xargs)
    if [ "$current_value" != "$desired_action_mail_acct" ]; then
        echo "Current action_mail_acct is set to: $current_value"
        read -p "Do you want to change action_mail_acct to $desired_action_mail_acct? (y/n): " user_choice
        if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
            sed -i "s/^action_mail_acct\s*=\s*\w\+$/action_mail_acct = $desired_action_mail_acct/" "$auditd_config_file"
            echo "action_mail_acct has been updated to $desired_action_mail_acct."
        else
            echo "action_mail_acct will not be changed."
        fi
    else
        echo "action_mail_acct is already set to $desired_action_mail_acct."
    fi
else
    echo "action_mail_acct is not set. Setting it to $desired_action_mail_acct."
    read -p "Do you want to proceed? (y/n): " proceed_choice
    if [[ "$proceed_choice" == "y" || "$proceed_choice" == "Y" ]]; then
        echo "action_mail_acct = $desired_action_mail_acct" >> "$auditd_config_file"
        echo "action_mail_acct has been added to $auditd_config_file."
    fi
fi

# Update admin_space_left_action if not set correctly
if [[ -n "$current_admin_space_left_action" ]]; then
    current_value=$(echo "$current_admin_space_left_action" | cut -d '=' -f2 | xargs)
    if [ "$current_value" != "$desired_admin_space_left_action" ]; then
        echo "Current admin_space_left_action is set to: $current_value"
        read -p "Do you want to change admin_space_left_action to $desired_admin_space_left_action? (y/n): " user_choice
        if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
            sed -i "s/^admin_space_left_action\s*=\s*\w\+$/admin_space_left_action = $desired_admin_space_left_action/" "$auditd_config_file"
            echo "admin_space_left_action has been updated to $desired_admin_space_left_action."
        else
            echo "admin_space_left_action will not be changed."
        fi
    else
        echo "admin_space_left_action is already set to $desired_admin_space_left_action."
    fi
else
    echo "admin_space_left_action is not set. Setting it to $desired_admin_space_left_action."
    read -p "Do you want to proceed? (y/n): " proceed_choice
    if [[ "$proceed_choice" == "y" || "$proceed_choice" == "Y" ]]; then
        echo "admin_space_left_action = $desired_admin_space_left_action" >> "$auditd_config_file"
        echo "admin_space_left_action has been added to $auditd_config_file."
    fi
fi
