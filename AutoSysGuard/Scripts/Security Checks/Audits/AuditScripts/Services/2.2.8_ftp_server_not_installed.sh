# 2.2.8 Ensure FTP Server is not installed (Automated)
#!/bin/bash

# Function to check if vsftpd is installed
check_vsftpd_installed() {
    dpkg -l | grep -q "^ii\s*vsftpd" || dpkg -l | grep -q "^ii\s*vsftpd-"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "vsftpd is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_vsftpd;;
        n|N ) echo "vsftpd removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove vsftpd
remove_vsftpd() {
    echo "Removing vsftpd..."
    sudo apt purge -y vsftpd
    if [[ $? -eq 0 ]]; then
        echo "vsftpd has been successfully removed."
    else
        echo "Failed to remove vsftpd. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_vsftpd_installed; then
    echo "vsftpd is currently installed."
    prompt_user
else
    echo "vsftpd is not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for vsftpd:"
dpkg -l | grep vsftpd || echo "No vsftpd packages found."
