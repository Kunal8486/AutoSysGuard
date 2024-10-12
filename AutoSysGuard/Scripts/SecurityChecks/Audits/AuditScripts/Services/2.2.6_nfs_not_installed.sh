# 2.2.6 Ensure NFS is not installed (Automated)
#!/bin/bash

# Function to check if nfs-kernel-server is installed
check_nfs_installed() {
    if dpkg -l | grep -q "^ii\s*nfs-kernel-server"; then
        return 0  # nfs-kernel-server is installed
    else
        return 1  # nfs-kernel-server is not installed
    fi
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "nfs-kernel-server is currently installed. Do you want to remove it? (y/n): " choice
    case "$choice" in
        y|Y ) remove_nfs;;
        n|N ) echo "nfs-kernel-server removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove nfs-kernel-server
remove_nfs() {
    echo "Removing nfs-kernel-server..."
    sudo apt purge -y nfs-kernel-server
    if [[ $? -eq 0 ]]; then
        echo "nfs-kernel-server has been successfully removed."
    else
        echo "Failed to remove nfs-kernel-server. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_nfs_installed; then
    echo "nfs-kernel-server is currently installed."
    prompt_user
else
    echo "nfs-kernel-server is not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for nfs-kernel-server:"
dpkg -l | grep nfs-kernel-server || echo "nfs-kernel-server is not installed or not found in package manager."
