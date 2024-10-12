#!/bin/bash

# Function to audit NTP configuration
audit_ntp_config() {
    echo "Checking NTP configuration..."
    
    # Check if /etc/ntp.conf exists
    if [[ ! -f /etc/ntp.conf ]]; then
        echo "Error: /etc/ntp.conf not found. Ensure NTP is installed."
        return 1
    fi

    # Check if ntp.conf contains at least one pool line or three server lines
    grep_output=$(grep -P -- '^\h*(server|pool)\h+\H+' /etc/ntp.conf 2>/dev/null)
    pool_count=$(echo "$grep_output" | grep -c "pool")
    server_count=$(echo "$grep_output" | grep -c "server")

    if [[ $pool_count -ge 1 || $server_count -ge 3 ]]; then
        echo "Audit Passed: NTP configuration is compliant."
        echo "$grep_output"
        return 0
    else
        echo "Audit Failed: NTP configuration is non-compliant."
        echo "$grep_output"
        return 1
    fi
}

# Function to apply remediation for NTP configuration
remediate_ntp_config() {
    echo "Applying remediation..."

    # Prompt user to select mode: pool or server
    while true; do
        read -p "Enter pool or server mode (pool/server): " mode
        if [[ "$mode" == "pool" || "$mode" == "server" ]]; then
            break
        else
            echo "Invalid mode selected. Please enter 'pool' or 'server'."
        fi
    done

    # Handle pool or server mode inputs
    if [[ "$mode" == "pool" ]]; then
        read -p "Enter pool address (e.g., time.nist.gov): " pool_address
        echo "pool $pool_address iburst" >> /etc/ntp.conf
    elif [[ "$mode" == "server" ]]; then
        read -p "Enter first server address (e.g., time-a-g.nist.gov): " server1
        read -p "Enter second server address (e.g., 132.163.97.3): " server2
        read -p "Enter third server address (e.g., time-d-b.nist.gov): " server3
        echo "server $server1 iburst" >> /etc/ntp.conf
        echo "server $server2 iburst" >> /etc/ntp.conf
        echo "server $server3 iburst" >> /etc/ntp.conf
    fi
    
    # Restart NTP service to apply changes
    systemctl restart ntp
    echo "NTP configuration updated and service restarted."
}

# Function to remove NTP if another service is in use
remove_ntp() {
    echo "Removing NTP as another time synchronization service is in use..."
    apt purge -y ntp
    echo "NTP has been removed from the system."
}

# Main Script
if audit_ntp_config; then
    echo "No remediation needed."
else
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_ntp_config
    else
        read -p "Is another time synchronization service in use? (y/n): " other_service
        if [[ "$other_service" == "y" || "$other_service" == "Y" ]]; then
            remove_ntp
        else
            echo "No action taken. NTP configuration remains non-compliant."
        fi
    fi
fi
