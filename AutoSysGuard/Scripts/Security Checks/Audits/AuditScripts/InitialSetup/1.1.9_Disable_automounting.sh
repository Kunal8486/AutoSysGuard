#!/bin/bash

# Function to check if autofs is installed
check_autofs_installed() {
    echo "Checking if autofs is installed..."
    if dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' | grep -q '^autofs'; then
        echo "The autofs package is installed."
        return 0  # Return 0 if autofs is installed
    else
        echo "The autofs package is NOT installed."
        return 1  # Return 1 if autofs is not installed
    fi
}

# Function to check if any packages depend on autofs
check_autofs_dependencies() {
    echo "Checking for dependencies on autofs..."
    if apt-cache rdepends autofs | grep -q 'Reverse Depends: '; then
        echo "Other packages depend on autofs."
        return 0  # Return 0 if dependencies exist
    else
        echo "No other packages depend on autofs."
        return 1  # Return 1 if no dependencies exist
    fi
}

# Function to check if autofs is enabled
check_autofs_enabled() {
    echo "Checking if autofs is enabled..."
    if systemctl is-enabled autofs 2>/dev/null | grep -q 'enabled'; then
        echo "The autofs service is enabled."
        return 0  # Return 0 if enabled
    else
        echo "The autofs service is NOT enabled."
        return 1  # Return 1 if not enabled
    fi
}

# Function to remove autofs
remove_autofs() {
    echo "Removing autofs package..."
    sudo apt purge autofs -y
    echo "autofs has been removed."
}

# Function to mask autofs
mask_autofs() {
    echo "Stopping and masking autofs service..."
    sudo systemctl stop autofs
    sudo systemctl mask autofs
    echo "autofs service has been masked."
}

# Main script execution
if check_autofs_installed; then
    if check_autofs_dependencies; then
        echo "Since other packages depend on autofs, masking it instead of removal."
        if check_autofs_enabled; then
            mask_autofs
        else
            echo "No action needed. autofs is already not enabled."
        fi
    else
        read -p "Would you like to remove the autofs package? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            remove_autofs
        else
            echo "No action taken. autofs remains installed."
        fi
    fi
else
    echo "No action needed. autofs is not installed."
fi
