# 3.4.3.1.3 Ensure ufw is uninstalled or disabled with iptables (Automated)
#!/bin/bash

# Function to check if ufw is installed
check_ufw_installed() {
    echo "Checking if ufw is installed..."
    if dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' ufw | grep -q "not-installed"; then
        echo "ufw is not installed."
        return 0
    else
        echo "ufw is installed."
        return 1
    fi
}

# Function to check if ufw is active
check_ufw_status() {
    echo "Checking if ufw is active..."
    if ufw status | grep -q "inactive"; then
        echo "ufw is inactive."
        return 0
    else
        echo "ufw is active."
        return 1
    fi
}

# Function to check if ufw is masked
check_ufw_masked() {
    echo "Checking if ufw is masked..."
    if systemctl is-enabled ufw | grep -q "masked"; then
        echo "ufw service is masked."
        return 0
    else
        echo "ufw service is not masked."
        return 1
    fi
}

# Function to remove ufw
remove_ufw() {
    echo "Removing ufw..."
    apt purge -y ufw
    if [ $? -eq 0 ]; then
        echo "ufw removed successfully."
    else
        echo "Failed to remove ufw."
    fi
}

# Function to disable and mask ufw
disable_and_mask_ufw() {
    echo "Disabling and masking ufw..."
    ufw disable
    systemctl stop ufw
    systemctl mask ufw
    if [ $? -eq 0 ]; then
        echo "ufw disabled and masked successfully."
    else
        echo "Failed to disable and mask ufw."
    fi
}

# Main audit function
run_audit() {
    echo "Running ufw audit..."

    # Check if ufw is installed
    if check_ufw_installed; then
        echo "Audit passed: ufw is not installed."
    else
        # If ufw is installed, check if user wants to remove it
        read -p "ufw is installed. Would you like to remove it? (y/n): " response
        if [ "$response" == "y" ]; then
            remove_ufw
        else
            echo "Remediation skipped for removing ufw."
        fi
    fi

    # Check if ufw is active
    if check_ufw_status; then
        echo "Audit passed: ufw is inactive."
    else
        # If ufw is active, check if user wants to disable and mask it
        read -p "ufw is active. Would you like to disable and mask it? (y/n): " response
        if [ "$response" == "y" ]; then
            disable_and_mask_ufw
        else
            echo "Remediation skipped for disabling and masking ufw."
        fi
    fi

    # Check if ufw is masked
    if check_ufw_masked; then
        echo "Audit passed: ufw service is masked."
    else
        # If ufw is not masked, check if user wants to mask it
        read -p "ufw service is not masked. Would you like to mask it? (y/n): " response
        if [ "$response" == "y" ]; then
            disable_and_mask_ufw
        else
            echo "Remediation skipped for masking ufw."
        fi
    fi

    echo "Audit complete."
}

# Run the audit
run_audit
