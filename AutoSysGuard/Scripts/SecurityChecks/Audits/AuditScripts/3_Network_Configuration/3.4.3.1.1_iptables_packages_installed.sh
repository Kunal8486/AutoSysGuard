#!/bin/bash

# Function to check if iptables packages are installed
check_iptables_installed() {
    echo "Checking if iptables and iptables-persistent are installed..."

    iptables_installed=$(apt list iptables | grep -i installed)
    persistent_installed=$(apt list iptables-persistent | grep -i installed)

    # Check if iptables is installed
    if [ -z "$iptables_installed" ]; then
        echo "iptables is not installed."
        return 1
    else
        echo "iptables is installed."
    fi

    # Check if iptables-persistent is installed
    if [ -z "$persistent_installed" ]; then
        echo "iptables-persistent is not installed."
        return 1
    else
        echo "iptables-persistent is installed."
    fi

    return 0
}

# Function to install iptables packages
install_iptables() {
    echo "Installing iptables and iptables-persistent..."
    apt install -y iptables iptables-persistent

    if [ $? -eq 0 ]; then
        echo "iptables and iptables-persistent installed successfully."
    else
        echo "Failed to install iptables and iptables-persistent."
    fi
}

# Main audit function
run_audit() {
    echo "Running iptables audit..."

    # Check if iptables packages are installed
    if check_iptables_installed; then
        echo "Audit passed: iptables and iptables-persistent are installed."
    else
        # If iptables or iptables-persistent are missing, ask user to install them
        read -p "Would you like to install iptables and iptables-persistent? (y/n): " response
        if [ "$response" == "y" ]; then
            install_iptables
        else
            echo "Remediation skipped for iptables installation."
        fi
    fi

    echo "Audit complete."
}

# Run the audit
run_audit
