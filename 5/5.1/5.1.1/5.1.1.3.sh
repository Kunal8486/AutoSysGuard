#!/bin/bash

# Function to audit if journald is configured to compress large log files
audit_journald_compression() {
    echo "Auditing journald compression setting..."

    # Checking if Compress is set to 'yes' in any of the configuration files
    compression_status=$(grep -Psi '^\h*Compress\h*=\h*yes\b' /etc/systemd/journald.conf /etc/systemd/journald.conf.d/* 2>/dev/null)

    if [[ "$compression_status" != "" ]]; then
        echo "Audit: journald is configured to compress large log files."
    else
        echo "Audit: journald is not configured to compress large log files."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to apply the remediation
    read -p "Do you want to configure journald to compress large log files? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_journald_compression
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to configure journald to compress large log files and modify compression threshold
remediate_journald_compression() {
    echo "Remediation: Configuring journald to compress large log files..."

    # Adding the Compress=yes setting in /etc/systemd/journald.conf
    sudo sed -i '/^\s*Compress=/d' /etc/systemd/journald.conf
    echo "Compress=yes" | sudo tee -a /etc/systemd/journald.conf >/dev/null

    # Ask the user if they want to modify the compression threshold (default is 512 bytes)
    read -p "Do you want to modify the compression threshold from the default of 512 bytes? (y/n): " threshold_input

    if [[ "$threshold_input" == "y" || "$threshold_input" == "Y" ]]; then
        read -p "Enter the new threshold value (in bytes): " threshold_value
        sudo sed -i '/^\s*CompressThreshold=/d' /etc/systemd/journald.conf
        echo "CompressThreshold=$threshold_value" | sudo tee -a /etc/systemd/journald.conf >/dev/null
        echo "Compression threshold set to $threshold_value bytes."
    fi

    # Restarting the journald service
    sudo systemctl restart systemd-journald

    if [ $? -eq 0 ]; then
        echo "Remediation: journald configured successfully and service restarted."
    else
        echo "Error: Failed to configure journald or restart the service."
    fi
}

# Running the audit
audit_journald_compression
