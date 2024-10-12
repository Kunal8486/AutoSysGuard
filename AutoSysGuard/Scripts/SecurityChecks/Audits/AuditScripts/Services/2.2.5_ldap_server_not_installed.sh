# 2.2.5 Ensure LDAP server is not installed (Automated)
#!/bin/bash

# Function to check if slapd is installed
check_slapd_installed() {
    if dpkg -l | grep -q "^ii\s*slapd"; then
        return 0  # slapd is installed
    else
        return 1  # slapd is not installed
    fi
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "slapd is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_slapd;;
        n|N ) echo "slapd removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove slapd
remove_slapd() {
    echo "Removing slapd..."
    sudo apt purge -y slapd
    if [[ $? -eq 0 ]]; then
        echo "slapd has been successfully removed."
    else
        echo "Failed to remove slapd. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_slapd_installed; then
    echo "slapd is currently installed."
    prompt_user
else
    echo "slapd is not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for slapd:"
dpkg -l | grep slapd || echo "slapd is not installed or not found in package manager."
