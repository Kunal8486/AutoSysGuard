#!/bin/bash

# Function to check if /home is mounted
check_home_mounted() {
    echo "Checking if /home is mounted..."
    if findmnt -kn /home > /dev/null; then
        echo "/home is mounted."
        return 0  # Return 0 if /home is mounted
    else
        echo "/home is NOT mounted."
        return 1  # Return 1 if /home is not mounted
    fi
}

# Function to provide remediation instructions
provide_remediation() {
    echo "Remediation Options:"
    echo "1. For new installations, create a custom partition setup during installation and specify a separate partition for /home."
    echo "2. For systems that were previously installed, create a new partition and configure /etc/fstab as appropriate."
}

# Main script execution
if check_home_mounted; then
    echo "No remediation needed."
else
    provide_remediation
    echo "Please take the appropriate action to configure /home."
fi
