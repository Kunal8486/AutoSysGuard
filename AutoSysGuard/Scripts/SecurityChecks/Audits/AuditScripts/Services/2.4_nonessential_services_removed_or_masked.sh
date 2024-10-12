# 2.4 Ensure nonessential services are removed or masked (Manual)

#!/bin/bash

# Function to check listening services and their status
check_listening_services() {
    ss -plntu
}

# Function to prompt for action on nonessential services
handle_service() {
    local service_name=$1
    local package_name=$2

    echo "Service: $service_name"
    read -p "Is this service required? (y/n): " choice

    case "$choice" in
        y|Y )
            echo "Stopping and masking the service..."
            sudo systemctl stop "${service_name}.socket"
            sudo systemctl stop "${service_name}.service"
            sudo systemctl mask "${service_name}.socket"
            sudo systemctl mask "${service_name}.service"
            echo "$service_name has been stopped and masked.";;
        n|N )
            echo "Removing the package containing the service..."
            sudo apt purge --auto-remove "$package_name" -y
            echo "$package_name has been removed.";;
        * )
            echo "Invalid choice. Please enter y or n.";;
    esac
}

# Main script execution
echo "Checking listening services..."
check_listening_services

# This is a placeholder. The user should provide the services and their associated package names.
# Example: 
# handle_service "httpd" "apache2"  # For Apache service
# handle_service "sshd" "openssh-server"  # For SSH service

# The following lines should be populated based on the output of ss -plntu
# Example usage:
handle_service "apache2" "apache2"   # Replace with actual service and package name
handle_service "sshd" "openssh-server"  # Replace with actual service and package name

echo "Audit and remediation process completed."
