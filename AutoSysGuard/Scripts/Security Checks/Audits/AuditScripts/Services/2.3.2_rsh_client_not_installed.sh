# 2.3.2 Ensure rsh client is not installed (Automated)

#!/bin/bash

# Function to check if rsh-client is installed
check_rsh_client_installed() {
    dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' rsh-client | grep -P '^rsh-client\s+unknown\s+ok\s+not-installed' > /dev/null
    return $?
}

# Function to apply remediation by removing rsh-client
apply_remediation() {
    echo "Uninstalling rsh-client..."
    sudo apt purge rsh-client -y
    if [[ $? -eq 0 ]]; then
        echo "rsh-client has been successfully removed."
    else
        echo "Failed to remove rsh-client. Please check your permissions or package status."
    fi
}

# Main script execution
echo "Checking rsh-client installation status..."

if check_rsh_client_installed; then
    echo "rsh-client is not installed."
else
    echo "rsh-client is currently installed."
    read -p "Do you want to uninstall the rsh-client package? (y/n): " user_response
    if [[ "$user_response" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No changes made to the rsh-client package."
    fi
fi

