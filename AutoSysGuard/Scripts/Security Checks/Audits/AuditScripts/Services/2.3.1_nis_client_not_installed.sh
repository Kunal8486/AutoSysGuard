# 2.3.1 Ensure NIS Client is not installed (Automated)
#!/bin/bash

# Function to check if NIS is installed
check_nis_installed() {
    dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' nis | grep -P '^nis\s+unknown\s+ok\s+not-installed' > /dev/null
    return $?
}

# Function to apply remediation by removing NIS
apply_remediation() {
    echo "Uninstalling NIS..."
    sudo apt purge nis -y
    if [[ $? -eq 0 ]]; then
        echo "NIS has been successfully removed."
    else
        echo "Failed to remove NIS. Please check your permissions or package status."
    fi
}

# Main script execution
echo "Checking NIS installation status..."

if check_nis_installed; then
    echo "NIS is not installed."
else
    echo "NIS is currently installed."
    read -p "Do you want to uninstall the NIS package? (y/n): " user_response
    if [[ "$user_response" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No changes made to the NIS package."
    fi
fi
