#!/bin/bash

# Function to audit rsyslog installation
audit_rsyslog() {
    echo "Auditing rsyslog installation..."

    # Check if rsyslog is installed
    if dpkg-query -W -f='${binary:Package}\t${Status}\n' rsyslog 2>/dev/null | grep -q "install ok installed"; then
        echo "Audit: rsyslog is installed."
    else
        echo "Audit: rsyslog is not installed."
        prompt_installation
    fi
}

# Function to prompt the user for installation
prompt_installation() {
    read -p "Do you want to install rsyslog? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        install_rsyslog
    else
        echo "You chose not to install rsyslog. Exiting."
    fi
}

# Function to install rsyslog
install_rsyslog() {
    echo "Installing rsyslog..."

    # Install rsyslog
    sudo apt install rsyslog -y

    if [ $? -eq 0 ]; then
        echo "Installation successful: rsyslog has been installed."
    else
        echo "Error: Failed to install rsyslog."
    fi
}

# Run the audit
audit_rsyslog
