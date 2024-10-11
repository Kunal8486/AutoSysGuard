#!/bin/bash

# Function to audit if journald is configured to persist logs to disk
audit_journald_persistence() {
    echo "Auditing journald log persistence setting..."

    # Checking if Storage is set to 'persistent' in any of the configuration files
    persistence_status=$(grep -Psi '^\h*Storage\h*=\h*persistent\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/* 2>/dev/null)

    if [[ "$persistence_status" != "" ]]; then
        echo "Audit: journald is configured to persist logs to disk."
    else
        echo "Audit: journald is not configured to persist logs to disk."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to apply the remediation
    read -p "Do you want to configure journald to persist logs to disk? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_journald_persistence
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to configure journald to persist logs to disk
remediate_journald_persistence() {
    echo "Remediation: Configuring journald to persist logs to disk..."

    # Adding the Storage=persistent setting to /etc/systemd/journald.conf
    sudo sed -i '/^\s*Storage=/d' /etc/systemd/journald.conf
    echo "Storage=persistent" | sudo tee -a /etc/systemd/journald.conf >/dev/null

    # Restarting the journald service
    sudo systemctl restart systemd-journald

    if [ $? -eq 0 ]; then
        echo "Remediation: journald configured successfully and service restarted."
    else
        echo "Error: Failed to configure journald or restart the service."
    fi
}

# Running the audit
audit_journald_persistence
