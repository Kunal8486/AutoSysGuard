#!/usr/bin/env bash

# Initialize variables
package_name="prelink"
install_status=""

# Function to check if prelink is installed
check_prelink_installed() {
    install_status=$(dpkg-query -W -f='${Status}\n' "$package_name" 2>/dev/null)
}

# Function to apply remediation
apply_remediation() {
    echo "Restoring binaries to normal..."
    prelink -ua
    echo "Uninstalling prelink..."
    apt purge -y "$package_name"
    echo "Remediation applied. Prelink has been uninstalled."
}

# Check if prelink is installed
check_prelink_installed

# Assess the status and output the results
if [[ $install_status == *"install ok installed"* ]]; then
    echo "Audit Result:\n ** FAIL **\n - \"$package_name\" is installed."
    read -p "Do you want to apply remediation? (y/n): " user_choice

    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
else
    echo "Audit Result:\n ** PASS **\n - \"$package_name\" is not installed."
fi
