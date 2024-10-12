#!/bin/bash

# Function to audit journald ForwardToSyslog configuration
audit_journald_forward_to_rsyslog() {
    echo "Auditing journald ForwardToSyslog configuration..."

    # Check the ForwardToSyslog setting in journald configuration
    forward_to_syslog=$(grep -E '^\s*ForwardToSyslog' /etc/systemd/journald.conf)

    if [[ -z "$forward_to_syslog" ]]; then
        echo "Audit: ForwardToSyslog is not set in /etc/systemd/journald.conf."
        prompt_set_forward_to_syslog
    elif [[ "$forward_to_syslog" == *"yes"* ]]; then
        echo "Audit: ForwardToSyslog is set to 'yes'."
    else
        echo "Audit: ForwardToSyslog is set to 'no'."
        prompt_set_forward_to_syslog
    fi
}

# Function to prompt the user to set ForwardToSyslog
prompt_set_forward_to_syslog() {
    read -p "Do you want to set ForwardToSyslog to 'yes' in /etc/systemd/journald.conf? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        set_forward_to_syslog
    else
        echo "You chose not to modify the ForwardToSyslog setting. Exiting."
    fi
}

# Function to set ForwardToSyslog in journald configuration
set_forward_to_syslog() {
    echo "Setting ForwardToSyslog to 'yes' in /etc/systemd/journald.conf..."

    # Edit the configuration file to add/modify ForwardToSyslog
    sudo sed -i '/^\s*ForwardToSyslog/c\ForwardToSyslog=yes' /etc/systemd/journald.conf

    if [ $? -eq 0 ]; then
        echo "ForwardToSyslog set to 'yes'. Restarting rsyslog service..."

        # Restart the rsyslog service
        sudo systemctl restart rsyslog

        if [ $? -eq 0 ]; then
            echo "Successfully restarted rsyslog service."
        else
            echo "Error: Failed to restart rsyslog service."
        fi
    else
        echo "Error: Failed to update /etc/systemd/journald.conf."
    fi
}

# Run the audit
audit_journald_forward_to_rsyslog
