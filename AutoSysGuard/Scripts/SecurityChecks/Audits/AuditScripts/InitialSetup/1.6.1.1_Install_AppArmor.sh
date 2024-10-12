#!/usr/bin/env bash

# Function to check if AppArmor is installed
check_apparmor_installed() {
    # Querying the installed packages for AppArmor
    installed_packages=$(dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' | grep -E '^(apparmor|apparmor-utils)')
    
    if [[ -n "$installed_packages" ]]; then
        echo "AppArmor is installed:\n$installed_packages"
        return 0
    else
        echo "AppArmor is not installed."
        return 1
    fi
}

# Function to install AppArmor
install_apparmor() {
    echo "Installing AppArmor..."
    apt install -y apparmor apparmor-utils
    if [[ $? -eq 0 ]]; then
        echo "AppArmor and apparmor-utils have been successfully installed."
    else
        echo "Failed to install AppArmor. Please check your package manager."
    fi
}

# Main script execution
check_apparmor_installed
if [[ $? -ne 0 ]]; then
    read -p "Do you want to install AppArmor? (y/n): " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        install_apparmor
    else
        echo "Installation aborted by the user."
    fi
else
    echo "No action needed. AppArmor is already installed."
fi
