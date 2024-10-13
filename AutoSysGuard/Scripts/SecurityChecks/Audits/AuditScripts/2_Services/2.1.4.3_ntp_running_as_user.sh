#!/bin/bash

# Function to check if NTP is installed
check_ntp_installed() {
    if ! dpkg -l | grep -q ntp; then
        echo "Error: NTP is not installed on this system."
        echo "You might be using an alternative time synchronization service like 'chrony' or 'systemd-timesyncd'."
        echo "If NTP is required, please install it with: sudo apt install ntp"
        return 1
    fi
    return 0
}

# Function to audit the NTP daemon user
audit_ntp_user() {
    echo "Checking if ntpd daemon is running as user 'ntp'..."
    ntpd_user=$(ps -ef | awk '(/[n]tpd/ && $1!="ntp") { print $1 }')
    
    if [[ -z "$ntpd_user" ]]; then
        echo "Audit Passed: ntpd daemon is running as user 'ntp'."
    else
        echo "Audit Failed: ntpd daemon is running as user '$ntpd_user' instead of 'ntp'."
    fi

    # Check the RUNASUSER setting in /usr/lib/ntp/ntp-systemd-wrapper
    echo "Checking RUNASUSER setting in /usr/lib/ntp/ntp-systemd-wrapper..."
    if [[ -f /usr/lib/ntp/ntp-systemd-wrapper ]]; then
        if grep -P -- '^\h*RUNASUSER=ntp' /usr/lib/ntp/ntp-systemd-wrapper >/dev/null 2>&1; then
            echo "Audit Passed: RUNASUSER is set to 'ntp'."
            return 0
        else
            echo "Audit Failed: RUNASUSER is not set to 'ntp'."
            return 1
        fi
    else
        echo "Error: /usr/lib/ntp/ntp-systemd-wrapper not found. NTP might not be properly installed."
        return 1
    fi
}

# Function to apply remediation
remediate_ntp_user() {
    echo "Applying remediation..."

    # Check if the wrapper file exists before trying to modify it
    if [[ -f /usr/lib/ntp/ntp-systemd-wrapper ]]; then
        if grep -P -- '^\h*RUNASUSER=' /usr/lib/ntp/ntp-systemd-wrapper >/dev/null 2>&1; then
            sed -i 's/^RUNASUSER=.*/RUNASUSER=ntp/' /usr/lib/ntp/ntp-systemd-wrapper
            echo "RUNASUSER updated to 'ntp' in /usr/lib/ntp/ntp-systemd-wrapper."
        else
            echo "RUNASUSER=ntp" >> /usr/lib/ntp/ntp-systemd-wrapper
            echo "RUNASUSER=ntp added to /usr/lib/ntp/ntp-systemd-wrapper."
        fi
    else
        echo "Error: /usr/lib/ntp/ntp-systemd-wrapper not found. Ensure NTP is installed properly."
        return 1
    fi
    
    # Restart the NTP service
    if systemctl restart ntp.service; then
        echo "NTP service restarted successfully."
    else
        echo "Failed to restart NTP service. Ensure ntp is installed and configured properly."
    fi
}

# Main script execution
check_ntp_installed
if [[ $? -ne 0 ]]; then
    exit 1
fi

audit_ntp_user
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        remediate_ntp_user
    else
        echo "No action taken. NTP configuration remains non-compliant."
    fi
else
    echo "NTP configuration is compliant. No remediation needed."
fi
