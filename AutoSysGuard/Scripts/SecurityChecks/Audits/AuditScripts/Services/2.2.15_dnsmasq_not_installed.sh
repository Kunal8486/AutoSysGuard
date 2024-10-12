#!/bin/bash

# Function to check if dnsmasq or dnsmasq-base is installed
check_dnsmasq_installed() {
    dpkg -l | grep -E "dnsmasq|dnsmasq-base" | grep -q "^ii"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "dnsmasq or dnsmasq-base is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_dnsmasq;;
        n|N ) echo "No changes were made to dnsmasq installation."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove dnsmasq and dnsmasq-base
remove_dnsmasq() {
    echo "Removing dnsmasq and dnsmasq-base..."
    sudo apt purge -y dnsmasq dnsmasq-base
    if [[ $? -eq 0 ]]; then
        echo "dnsmasq and dnsmasq-base have been successfully removed."
    else
        echo "Failed to remove dnsmasq or dnsmasq-base. Please check your permissions or package manager."
    fi
}

# Function to check for remaining dnsmasq packages
check_remaining_packages() {
    echo "Checking for remaining dnsmasq packages:"
    dpkg -l | grep -E "dnsmasq|dnsmasq-base" || echo "No remaining dnsmasq packages found."
}

# Main script execution
if check_dnsmasq_installed; then
    echo "dnsmasq or dnsmasq-base is currently installed."
    prompt_user
else
    echo "dnsmasq and dnsmasq-base are not installed."
    exit 0
fi

# Check for remaining dnsmasq packages
check_remaining_packages
