#!/bin/bash

# Function to audit journald log rotation settings
audit_journald_log_rotation() {
    echo "Auditing journald log rotation configuration..."

    # Check for log rotation settings in the main configuration and custom files
    echo "Checking /etc/systemd/journald.conf..."
    log_rotation_settings=$(grep -E '^(SystemMaxUse|SystemKeepFree|RuntimeMaxUse|RuntimeKeepFree|MaxFileSec)=' /etc/systemd/journald.conf)

    echo "Checking /etc/systemd/journald.conf.d/*..."
    for conf_file in /etc/systemd/journald.conf.d/*.conf; do
        if [[ -f "$conf_file" ]]; then
            log_rotation_settings+="\n$(grep -E '^(SystemMaxUse|SystemKeepFree|RuntimeMaxUse|RuntimeKeepFree|MaxFileSec)=' "$conf_file")"
        fi
    done

    if [[ -z "$log_rotation_settings" ]]; then
        echo "Audit: No log rotation settings found in journald configuration."
        prompt_remediation
    else
        echo -e "Audit: Found the following log rotation settings:\n$log_rotation_settings"
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    read -p "Do you want to review and configure log rotation settings according to site policy? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_journald_log_rotation
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to edit the journald configuration for log rotation
remediate_journald_log_rotation() {
    echo "Remediation: Editing journald log rotation configuration..."

    # Open the main configuration file for editing
    sudo nano /etc/systemd/journald.conf

    # If needed, also open custom configuration files
    for conf_file in /etc/systemd/journald.conf.d/*.conf; do
        if [[ -f "$conf_file" ]]; then
            echo "You may also edit: $conf_file"
            sudo nano "$conf_file"
        fi
    done

    # Restart the journald service to apply changes
    sudo systemctl restart systemd-journald

    if [ $? -eq 0 ]; then
        echo "Remediation: Configuration changes applied successfully and service restarted."
    else
        echo "Error: Failed to apply configuration changes or restart the service."
    fi
}

# Running the audit
audit_journald_log_rotation
