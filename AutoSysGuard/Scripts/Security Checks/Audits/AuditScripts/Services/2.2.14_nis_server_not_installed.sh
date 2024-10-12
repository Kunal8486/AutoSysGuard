# 2.2.14 Ensure NIS Server is not installed (Automated)
#!/bin/bash

# Function to check if nis is installed
check_nis_installed() {
    dpkg -l | grep -q "^ii\s*nis"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "nis is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_nis;;
        n|N ) echo "No changes were made to nis installation."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove nis
remove_nis() {
    echo "Removing nis..."
    sudo apt purge -y nis
    if [[ $? -eq 0 ]]; then
        echo "nis has been successfully removed."
    else
        echo "Failed to remove nis. Please check your permissions or package manager."
    fi
}

# Function to check for remaining nis packages
check_remaining_packages() {
    echo "Checking for remaining nis packages:"
    dpkg -l | grep nis || echo "No remaining nis packages found."
}

# Main script execution
if check_nis_installed; then
    echo "nis is currently installed."
    prompt_user
else
    echo "nis is not installed."
    exit 0
fi

# Check for remaining nis packages
check_remaining_packages
