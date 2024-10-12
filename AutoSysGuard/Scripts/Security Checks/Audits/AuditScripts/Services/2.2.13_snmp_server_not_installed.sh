# 2.2.13 Ensure SNMP Server is not installed (Automated)
#!/bin/bash

# Function to check if snmpd is installed
check_snmpd_installed() {
    dpkg -l | grep -q "^ii\s*snmpd"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "snmpd is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_snmpd;;
        n|N ) echo "No changes were made to snmpd installation."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove snmpd
remove_snmpd() {
    echo "Removing snmpd..."
    sudo apt purge -y snmpd
    if [[ $? -eq 0 ]]; then
        echo "snmpd has been successfully removed."
    else
        echo "Failed to remove snmpd. Please check your permissions or package manager."
    fi
}

# Function to check for remaining snmpd packages
check_remaining_packages() {
    echo "Checking for remaining snmpd packages:"
    dpkg -l | grep snmpd || echo "No remaining snmpd packages found."
}

# Main script execution
if check_snmpd_installed; then
    echo "snmpd is currently installed."
    prompt_user
else
    echo "snmpd is not installed."
    exit 0
fi

# Check for remaining snmpd packages
check_remaining_packages
