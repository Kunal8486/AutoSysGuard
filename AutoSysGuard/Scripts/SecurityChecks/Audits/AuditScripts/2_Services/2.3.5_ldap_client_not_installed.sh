#!/bin/bash

# Function to check if ldap-utils is installed
check_ldap_installed() {
    dpkg-query -W -f='${Status}' ldap-utils 2>/dev/null | grep -q "install ok installed"
}

# Check if ldap-utils is installed
if check_ldap_installed; then
    echo "ldap-utils is currently installed."

    # Ask user for confirmation to uninstall
    read -p "Do you want to uninstall ldap-utils? (y/n): " choice
    case "$choice" in
        y|Y ) 
            echo "Uninstalling ldap-utils..."
            sudo apt-get purge --auto-remove ldap-utils -y
            echo "ldap-utils has been successfully removed.";;
        n|N ) 
            echo "ldap-utils will remain installed.";;
        * ) 
            echo "Invalid choice. Please enter y or n.";;
    esac
else
    echo "ldap-utils is not installed."
fi

# Optionally, provide a summary of the package status
echo "Verifying package status..."
dpkg-query -W -f='${binary:Package}\t${Status}\n' ldap-utils
