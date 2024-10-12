#!/bin/bash

# Function to audit journald default file permissions
audit_journald_permissions() {
    echo "Auditing journald default file permissions..."

    # Check for the override file
    if [[ -f "/etc/tmpfiles.d/systemd.conf" ]]; then
        echo "Override file found: /etc/tmpfiles.d/systemd.conf"
        permissions=$(grep -P '^\s*[0-9]{3}\s*\/var\/log\/journal' /etc/tmpfiles.d/systemd.conf)

        if [[ -z "$permissions" ]]; then
            echo "No specific permissions set in the override file."
            prompt_remediation
        else
            echo "Current permissions in the override file: $permissions"
            check_permissions "$permissions"
        fi
    else
        echo "No override file found, checking default configuration..."
        permissions=$(grep -P '^\s*[0-9]{3}\s*\/var\/log\/journal' /usr/lib/tmpfiles.d/systemd.conf)

        if [[ -z "$permissions" ]]; then
            echo "No specific permissions found in the default configuration."
            prompt_remediation
        else
            echo "Current permissions in the default configuration: $permissions"
            check_permissions "$permissions"
        fi
    fi
}

# Function to check permissions and prompt for remediation
check_permissions() {
    local current_permissions="$1"
    local expected_permissions="0640"

    # Extract the actual permissions from the configuration
    actual_permissions=$(echo "$current_permissions" | awk '{print $1}')

    if [[ "$actual_permissions" == "$expected_permissions" || "$actual_permissions" == "0600" ]]; then
        echo "Audit: Permissions are set correctly to $actual_permissions."
    else
        echo "Audit: Permissions are set to $actual_permissions, which does not meet the expected $expected_permissions."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    read -p "Do you want to review and configure journald default file permissions? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_journald_permissions
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to remediate journald default file permissions
remediate_journald_permissions() {
    echo "Remediation: Editing journald file permissions configuration..."

    # Copy default configuration to override file if it doesn't exist
    if [[ ! -f "/etc/tmpfiles.d/systemd.conf" ]]; then
        sudo cp /usr/lib/tmpfiles.d/systemd.conf /etc/tmpfiles.d/systemd.conf
        echo "Copied /usr/lib/tmpfiles.d/systemd.conf to /etc/tmpfiles.d/systemd.conf"
    fi

    # Open the configuration file for editing
    sudo nano /etc/tmpfiles.d/systemd.conf

    echo "Ensure that the log file permissions are set to 0640 or as per site policy."

    # Restart the journald service to apply changes
    sudo systemctl restart systemd-journald

    if [ $? -eq 0 ]; then
        echo "Remediation: Configuration changes applied successfully and service restarted."
    else
        echo "Error: Failed to apply configuration changes or restart the service."
    fi
}

# Running the audit
audit_journald_permissions
