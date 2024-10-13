# 2.2.16 Ensure mail transfer agent is configured for local-only mode (Automated)
#!/bin/bash

# Function to check if MTA is listening on non-loopback addresses
check_mta_loopback() {
    if ss -lntu | grep -P ':25\b' | grep -Pv '\h+(127\.0\.0\.1|\[?::1\]?):25\b' > /dev/null; then
        echo "MTA is listening on a non-loopback address."
        return 0
    else
        echo "MTA is correctly configured to listen only on loopback addresses."
        return 1
    fi
}

# Function to prompt the user for remediation
prompt_user() {
    read -p "Do you want to change the MTA configuration to listen only on loopback addresses? (y/n): " choice
    case "$choice" in
        y|Y ) apply_remediation;;
        n|N ) echo "No changes were made to MTA configuration."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to apply remediation
apply_remediation() {
    # Backup the original configuration file
    sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.bak
    echo "Backup of /etc/postfix/main.cf created as main.cf.bak."

    # Modify the configuration to set inet_interfaces to loopback-only
    sudo sed -i '/^inet_interfaces/c\inet_interfaces = loopback-only' /etc/postfix/main.cf

    # Restart postfix service
    sudo systemctl restart postfix
    if [[ $? -eq 0 ]]; then
        echo "Postfix has been successfully reconfigured to listen only on loopback addresses."
    else
        echo "Failed to restart postfix. Please check your permissions or service status."
    fi
}

# Main script execution
check_mta_loopback
if [[ $? -eq 0 ]]; then
    prompt_user
fi
