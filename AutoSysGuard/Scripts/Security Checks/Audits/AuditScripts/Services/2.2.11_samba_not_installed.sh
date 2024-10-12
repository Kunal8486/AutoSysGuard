#!/bin/bash

# Function to check if samba is installed
check_samba_installed() {
    dpkg -l | grep -q "^ii\s*samba"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "Samba is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_samba;;
        n|N ) echo "Samba removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove samba
remove_samba() {
    echo "Removing Samba..."
    sudo apt purge -y samba
    if [[ $? -eq 0 ]]; then
        echo "Samba has been successfully removed."
    else
        echo "Failed to remove Samba. Please check your permissions or package manager."
    fi
}

# Function to remove remaining samba-related packages
remove_remaining_packages() {
    echo "Removing remaining Samba-related packages..."
    sudo apt purge -y samba-common samba-common-bin samba-libs python3-samba libldb2 python3-ldb vlc-plugin-samba
    if [[ $? -eq 0 ]]; then
        echo "All remaining Samba-related packages have been successfully removed."
    else
        echo "Failed to remove remaining Samba-related packages. Please check your permissions or package manager."
    fi
}

# Function to check for remaining samba packages
check_remaining_packages() {
    echo "Checking for remaining Samba packages:"
    dpkg -l | grep samba || echo "No remaining Samba packages found."
}

# Main script execution
if check_samba_installed; then
    echo "Samba is currently installed."
    prompt_user
else
    echo "Samba is not installed."
fi

# Check for remaining Samba packages
check_remaining_packages

# Remove any remaining samba-related packages
remove_remaining_packages
