# 3.4.1.1 Ensure ufw is installed (Automated)
#!/usr/bin/env bash

# Check if UFW is installed
ufw_status=$(dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' ufw 2>/dev/null)

# Function to check installation status
check_ufw() {
    if [[ $ufw_status == *"ok installed"* ]]; then
        echo "UFW is installed."
        return 0
    else
        echo "UFW is NOT installed."
        return 1
    fi
}

# Check the installation status of UFW
check_ufw

# If UFW is not installed, prompt the user for remediation
if [ $? -ne 0 ]; then
    read -p "Do you want to install Uncomplicated Firewall (UFW)? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        echo "Installing UFW..."
        sudo apt update
        sudo apt install -y ufw
        
        if check_ufw; then
            echo "UFW has been successfully installed."
        else
            echo "Failed to install UFW. Please check your package manager and try again."
        fi
    else
        echo "No changes were made. UFW remains uninstalled."
    fi
else
    echo "No changes are needed. UFW is already installed."
fi
