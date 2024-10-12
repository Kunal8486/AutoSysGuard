#!/bin/bash

# Function to check if any bind9 package is installed
check_bind9_installed() {
    dpkg -l | grep -q "^ii\s*bind9" || dpkg -l | grep -q "^ii\s*bind9-"  # Check for bind9 or its sub-packages
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "bind9 is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_bind9;;
        n|N ) echo "bind9 removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove all bind9 related packages
remove_bind9() {
    echo "Removing bind9 and related packages..."
    sudo apt purge -y bind9 bind9-*  # This will remove all packages starting with bind9
    if [[ $? -eq 0 ]]; then
        echo "bind9 and related packages have been successfully removed."
    else
        echo "Failed to remove bind9. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_bind9_installed; then
    echo "bind9 is currently installed."
    prompt_user
else
    echo "bind9 is not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for bind9:"
dpkg -l | grep bind9 || echo "No bind9 packages found."
