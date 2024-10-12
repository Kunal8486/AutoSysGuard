#!/bin/bash

# Function to check if AIDE is installed
check_aide_installed() {
    echo "Checking if AIDE is installed..."
    if dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' aide 2>/dev/null | grep -q 'install ok installed'; then
        echo "AIDE is already installed."
        return 0  # Return 0 if AIDE is installed
    else
        echo "AIDE is NOT installed."
        return 1  # Return 1 if AIDE is not installed
    fi
}

# Function to install AIDE
install_aide() {
    echo "Installing AIDE and aide-common..."
    sudo apt install aide aide-common -y
    echo "AIDE has been installed."
}

# Function to mask AIDE service
mask_aide_service() {
    echo "Masking AIDE service to prevent it from starting automatically..."
    sudo systemctl mask aide
}

# Main script execution
if check_aide_installed; then
    echo "You can manually run 'aideinit' to initialize AIDE when you're ready."
else
    read -p "Would you like to install AIDE? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        install_aide
        mask_aide_service
        echo "You can manually run 'aideinit' to initialize AIDE when you're ready."
    else
        echo "No action taken. AIDE is not installed."
    fi
fi
