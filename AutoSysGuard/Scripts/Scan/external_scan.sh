#!/bin/bash

# Function to check if RKHunter is installed
check_rkhunter_installed() {
    if ! command -v rkhunter &> /dev/null
    then
        echo "RKHunter not found! Installing..."
        sudo apt-get update && sudo apt-get install rkhunter -y
    fi
}

# Function to scan the external drive with RKHunter
scan_drive() {
    echo "Starting scan of the external drive at: $1"
    echo "Updating RKHunter definitions..."
    
    # Update RKHunter definitions
    sudo rkhunter --update

    if [ $? -ne 0 ]; then
        echo "Failed to update RKHunter definitions. Continuing with the scan..."
    fi

    # Run the RKHunter scan on the external drive
    sudo rkhunter --check --rwo --sk --dir "$1"
    
    if [ $? -eq 0 ]; then
        echo "Scan completed successfully."
    else
        echo "Errors encountered during the scan. Check the log at /var/log/rkhunter.log for details."
    fi
}

# Main script starts here

echo "Checking for RKHunter installation..."
check_rkhunter_installed

# List available drives and prompt the user for the external drive path
echo "Listing all available drives:"
lsblk

# Prompt user to input the external drive mount point or path
echo -n "Enter the path to the external drive (e.g., /media/username/drive): "
read drive_path

# Check if the provided path exists
if [ ! -d "$drive_path" ]; then
    echo "Error: The provided path does not exist or is not a directory."
    exit 1
fi

# Confirm with the user before starting the scan
echo "You are about to scan the external drive at: $drive_path"
read -p "Are you sure you want to continue? (y/n) " choice

case "$choice" in 
  y|Y ) 
    scan_drive "$drive_path"
    ;;
  n|N ) 
    echo "Scan cancelled."
    exit 1
    ;;
  * ) 
    echo "Invalid input. Exiting."
    exit 1
    ;;
esac
