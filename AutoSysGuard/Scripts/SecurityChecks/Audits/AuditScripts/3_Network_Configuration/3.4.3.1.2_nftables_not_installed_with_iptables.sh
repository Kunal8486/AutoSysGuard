# 3.4.3.1.2 Ensure nftables is not installed with iptables (Automated)
#!/bin/bash

# Function to check if nftables is installed
check_nftables() {
    # Run dpkg-query to check the status of nftables
    result=$(dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' nftables 2>/dev/null)

    if [[ $result == *"nftables unknown ok not-installed not-installed"* ]]; then
        echo "Audit passed: nftables is not installed."
    else
        echo "Audit failed: nftables is installed."
        # Ask the user if they want to remediate the issue by removing nftables
        read -p "Would you like to remove nftables? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            remediate_nftables
        else
            echo "Remediation skipped."
        fi
    fi
}

# Function to remediate by removing nftables
remediate_nftables() {
    echo "Removing nftables..."
    sudo apt-get remove --purge nftables -y
    if [[ $? -eq 0 ]]; then
        echo "nftables has been successfully removed."
    else
        echo "Failed to remove nftables. Please check for errors."
    fi
}

# Start audit process
check_nftables
#!/bin/bash

# Function to check if nftables is installed
check_nftables() {
    # Run dpkg-query to check the status of nftables
    result=$(dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' nftables 2>/dev/null)

    if [[ $result == *"nftables unknown ok not-installed not-installed"* ]]; then
        echo "Audit passed: nftables is not installed."
    else
        echo "Audit failed: nftables is installed."
        # Ask the user if they want to remediate the issue by removing nftables
        read -p "Would you like to remove nftables? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            remediate_nftables
        else
            echo "Remediation skipped."
        fi
    fi
}

# Function to remediate by removing nftables
remediate_nftables() {
    echo "Removing nftables..."
    sudo apt-get remove --purge nftables -y
    if [[ $? -eq 0 ]]; then
        echo "nftables has been successfully removed."
    else
        echo "Failed to remove nftables. Please check for errors."
    fi
}

# Start audit process
check_nftables
