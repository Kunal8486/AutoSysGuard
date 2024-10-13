#!/bin/bash


# Define the expected configuration based on your environment
EXPECTED_URL="192.168.50.42"
EXPECTED_SERVER_KEY="/etc/ssl/private/journal-upload.pem"
EXPECTED_SERVER_CERT="/etc/ssl/certs/journal-upload.pem"
EXPECTED_TRUSTED_CERT="/etc/ssl/ca/trusted.pem"
CONFIG_FILE="/etc/systemd/journal-upload.conf"

# Function to audit systemd-journal-remote configuration
audit_systemd_journal_remote_config() {
    echo "Auditing systemd-journal-remote configuration..."

    # Checking if the configuration matches the expected settings
    url=$(grep -P "^ *URL=" "$CONFIG_FILE" | awk -F= '{print $2}' | xargs)
    server_key=$(grep -P "^ *ServerKeyFile=" "$CONFIG_FILE" | awk -F= '{print $2}' | xargs)
    server_cert=$(grep -P "^ *ServerCertificateFile=" "$CONFIG_FILE" | awk -F= '{print $2}' | xargs)
    trusted_cert=$(grep -P "^ *TrustedCertificateFile=" "$CONFIG_FILE" | awk -F= '{print $2}' | xargs)

    # Display current settings
    echo "Current configuration:"
    echo "URL: $url"
    echo "ServerKeyFile: $server_key"
    echo "ServerCertificateFile: $server_cert"
    echo "TrustedCertificateFile: $trusted_cert"

    # Check if the current settings match the expected values
    if [[ "$url" == "$EXPECTED_URL" && "$server_key" == "$EXPECTED_SERVER_KEY" && \
          "$server_cert" == "$EXPECTED_SERVER_CERT" && "$trusted_cert" == "$EXPECTED_TRUSTED_CERT" ]]; then
        echo "Audit: systemd-journal-remote is configured correctly. No remediation required."
    else
        echo "Audit: systemd-journal-remote is not configured correctly."
        prompt_remediation
    fi
}

# Function to prompt the user for remediation
prompt_remediation() {
    # Ask the user if they want to apply the remediation
    read -p "Do you want to apply the correct configuration? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        remediate_systemd_journal_remote_config
    else
        echo "You chose not to apply remediation. Exiting."
    fi
}

# Function to apply remediation (edit config and restart service)
remediate_systemd_journal_remote_config() {
    echo "Applying remediation: Updating configuration..."

    # Backup the existing configuration file
    sudo cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

    # Update the configuration file with the expected settings
    sudo bash -c "cat > $CONFIG_FILE" <<EOL
URL=$EXPECTED_URL
ServerKeyFile=$EXPECTED_SERVER_KEY
ServerCertificateFile=$EXPECTED_SERVER_CERT
TrustedCertificateFile=$EXPECTED_TRUSTED_CERT
EOL

    # Restart the systemd-journal-upload service
    echo "Restarting systemd-journal-upload service..."
    sudo systemctl restart systemd-journal-upload

    if [ $? -eq 0 ]; then
        echo "Remediation: Configuration updated and service restarted successfully."
    else
        echo "Error: Failed to restart systemd-journal-upload."
    fi
}

# Running the audit
audit_systemd_journal_remote_config
