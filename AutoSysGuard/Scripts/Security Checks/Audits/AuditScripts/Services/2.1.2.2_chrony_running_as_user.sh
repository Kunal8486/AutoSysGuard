#!/bin/bash

# Function to check if chronyd is running as _chrony
check_chrony() {
    echo "Checking if chronyd is running as _chrony user..."
    # Check if chronyd is running and not as _chrony user
    OUTPUT=$(ps -ef | awk '(/[c]hronyd/ && $1!="_chrony") { print $1 }')
    
    if [[ -n "$OUTPUT" ]]; then
        echo "Audit failed: chronyd is not running as _chrony user."
        return 1  # Indicate failure
    else
        echo "Audit passed: chronyd is running as _chrony user."
        return 0  # Indicate success
    fi
}

# Function for remediation
remediate() {
    # Check if chrony is installed
    if dpkg -l | grep -q chrony; then
        # Add user _chrony to /etc/chrony/chrony.conf
        echo "Adding user _chrony to /etc/chrony/chrony.conf..."
        echo "user _chrony" | sudo tee -a /etc/chrony/chrony.conf > /dev/null
        echo "Remediation applied: user _chrony added to chrony configuration."
    else
        echo "Chrony is not installed. Removing chrony from the system..."
        sudo apt purge chrony -y
        echo "Remediation applied: chrony has been removed."
    fi
}

# Main script execution
check_chrony
if [[ $? -ne 0 ]]; then
    # Prompt user for confirmation before applying remediation
    read -p "Do you want to apply remediation? (y/n): " choice
    case "$choice" in
        y|Y)
            remediate
            ;;
        n|N)
            echo "No remediation applied."
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi
