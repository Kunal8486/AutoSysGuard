#!/bin/bash

# Function to check if apache2 or related packages are installed
check_apache2_installed() {
    dpkg -l | grep -q "^ii\s*apache2" || dpkg -l | grep -q "^ii\s*apache2-bin" || \
    dpkg -l | grep -q "^ii\s*apache2-utils" || dpkg -l | grep -q "^ii\s*apache2-data" || \
    dpkg -l | grep -q "^ii\s*libapache2-mod-php"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "apache2 is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_apache2;;
        n|N ) echo "apache2 removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove apache2 and related packages
remove_apache2() {
    echo "Removing apache2 and related packages..."
    sudo apt purge -y apache2 apache2-bin apache2-data apache2-utils libapache2-mod-php
    if [[ $? -eq 0 ]]; then
        echo "apache2 and related packages have been successfully removed."
    else
        echo "Failed to remove apache2. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_apache2_installed; then
    echo "apache2 is currently installed."
    prompt_user
else
    echo "apache2 is not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for apache2:"
dpkg -l | grep apache2 || echo "No apache2 packages found."
