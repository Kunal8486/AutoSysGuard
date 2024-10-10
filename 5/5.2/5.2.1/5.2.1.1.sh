#!/bin/bash

# Function to check if auditd is installed
check_auditd_installed() {
    dpkg-query -W -f='${binary:Package}\t${Status}\n' | grep -E 'auditd|audispd-plugins' > /dev/null 2>&1
    return $?
}

# Function to install auditd
install_auditd() {
    echo "Installing auditd and audispd-plugins..."
    sudo apt install -y auditd audispd-plugins
}

# Audit Section
echo "Checking if auditd is installed..."

if check_auditd_installed; then
    echo -e "Auditd and audispd-plugins are already installed.\n"
else
    echo -e "Auditd or audispd-plugins is not installed.\n"
    install_auditd
fi

# Verification Section
echo "Verifying installation..."
if check_auditd_installed; then
    echo -e "Auditd and audispd-plugins have been successfully installed.\n"
else
    echo -e "Failed to install auditd and audispd-plugins. Please check the installation logs.\n"
fi
