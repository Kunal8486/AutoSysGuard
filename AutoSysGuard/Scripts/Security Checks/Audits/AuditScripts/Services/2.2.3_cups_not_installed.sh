#!/bin/bash

# Function to check if the main CUPS package is installed
check_cups_installed() {
    if dpkg -l | grep -q "^ii\s*cups$"; then
        return 0  # CUPS is installed
    else
        return 1  # CUPS is not installed
    fi
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "CUPS is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_cups;;
        n|N ) echo "CUPS removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove CUPS
remove_cups() {
    echo "Removing CUPS..."
    sudo apt purge -y cups
    if [[ $? -eq 0 ]]; then
        echo "CUPS has been successfully removed."
    else
        echo "Failed to remove CUPS. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_cups_installed; then
    echo "CUPS is currently installed."
    prompt_user
else
    echo "CUPS is not installed."
fi
