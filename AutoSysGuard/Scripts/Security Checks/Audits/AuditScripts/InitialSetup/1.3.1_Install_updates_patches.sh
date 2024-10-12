#!/bin/bash

# Function to check for available updates
check_updates() {
    echo "Checking for available updates..."
    available_updates=$(apt -s upgrade | grep -E 'upgraded, ')

    if [[ -n "$available_updates" ]]; then
        echo "Updates available:"
        echo "$available_updates"
        return 0  # Updates available
    else
        echo "No updates or patches available."
        return 1  # No updates
    fi
}

# Function to upgrade packages
upgrade_packages() {
    echo "Upgrading packages..."
    sudo apt upgrade -y
    echo "Packages upgraded."
}

# Function to perform a dist-upgrade
dist_upgrade_packages() {
    echo "Performing dist-upgrade..."
    sudo apt dist-upgrade -y
    echo "Packages upgraded with dist-upgrade."
}

# Main script execution
if check_updates; then
    echo "Would you like to upgrade the packages? (Enter 'upgrade', 'dist-upgrade', or 'exit' to quit)"
    read choice
    case $choice in
        upgrade)
            upgrade_packages
            ;;
        dist-upgrade)
            dist_upgrade_packages
            ;;
        exit)
            echo "Exiting without making changes."
            ;;
        *)
            echo "Invalid choice. Exiting."
            ;;
    esac
else
    echo "Audit complete. No action needed."
fi
