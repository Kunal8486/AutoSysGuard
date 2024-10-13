#!/bin/bash

# Function to check if gdm3 is installed
check_gdm3_installed() {
    echo "Checking if gdm3 is installed..."
    
    # Audit command to check if gdm3 is installed
    dpkg_status=$(dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' gdm3 2>/dev/null)
    
    if echo "$dpkg_status" | grep -q "not-installed"; then
        echo "Audit passed: gdm3 is not installed."
        return 0
    else
        echo "Audit failed: gdm3 is installed."
        return 1
    fi
}

# Function to uninstall gdm3
remediate_gdm3_removal() {
    echo "Uninstalling gdm3..."
    
    # Uninstall gdm3
    apt purge -y gdm3
    
    echo "gdm3 has been successfully uninstalled."
}

# Main logic
check_gdm3_installed
if [[ $? -eq 1 ]]; then
    # If audit failed, ask the user to apply remediation
    read -p "Do you want to uninstall gdm3? (y/n): " user_input
    
    if [[ "$user_input" == "y" ]]; then
        remediate_gdm3_removal
    else
        echo "gdm3 was not uninstalled. Please uninstall it manually if required."
    fi
else
    echo "No remediation is needed."
fi
