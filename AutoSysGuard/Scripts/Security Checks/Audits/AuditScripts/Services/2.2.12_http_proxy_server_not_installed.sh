#!/bin/bash

# Function to check if squid is installed
check_squid_installed() {
    dpkg -l | grep -q "^ii\s*squid"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "Squid is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_squid;;
        n|N ) echo "No changes were made to Squid installation."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove squid
remove_squid() {
    echo "Removing Squid..."
    sudo apt purge -y squid
    if [[ $? -eq 0 ]]; then
        echo "Squid has been successfully removed."
    else
        echo "Failed to remove Squid. Please check your permissions or package manager."
    fi
}

# Function to check for remaining squid packages
check_remaining_packages() {
    echo "Checking for remaining Squid packages:"
    dpkg -l | grep squid || echo "No remaining Squid packages found."
}

# Main script execution
if check_squid_installed; then
    echo "Squid is currently installed."
    prompt_user
else
    echo "Squid is not installed."
    exit 0
fi

# Check for remaining Squid packages
check_remaining_packages
