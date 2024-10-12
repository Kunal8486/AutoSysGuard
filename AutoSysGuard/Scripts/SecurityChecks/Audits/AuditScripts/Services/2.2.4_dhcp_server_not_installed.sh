# 2.2.4 Ensure DHCP Server is not installed (Automated)
#!/bin/bash

# Function to check if isc-dhcp-server is installed
check_dhcp_server_installed() {
    if dpkg -l | grep -q "^ii\s*isc-dhcp-server"; then
        return 0  # isc-dhcp-server is installed
    else
        return 1  # isc-dhcp-server is not installed
    fi
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "isc-dhcp-server is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_dhcp_server;;
        n|N ) echo "isc-dhcp-server removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove isc-dhcp-server
remove_dhcp_server() {
    echo "Removing isc-dhcp-server..."
    sudo apt purge -y isc-dhcp-server
    if [[ $? -eq 0 ]]; then
        echo "isc-dhcp-server has been successfully removed."
    else
        echo "Failed to remove isc-dhcp-server. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_dhcp_server_installed; then
    echo "isc-dhcp-server is currently installed."
    prompt_user
else
    echo "isc-dhcp-server is not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for isc-dhcp-server:"
dpkg -l | grep isc-dhcp-server || echo "isc-dhcp-server is not installed or not found in package manager."
