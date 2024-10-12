#!/usr/bin/env bash

# Function to check if Apport is enabled
check_apport_enabled() {
    if dpkg-query -s apport > /dev/null 2>&1; then
        enabled_status=$(grep -Psi '^\h*enabled\h*=\h*[^0]\b' /etc/default/apport)
        if [ -n "$enabled_status" ]; then
            return 0 # Apport is enabled
        fi
    fi
    return 1 # Apport is not enabled
}

# Function to check if Apport service is active
check_apport_service_active() {
    active_status=$(systemctl is-active apport.service | grep '^active')
    if [ -n "$active_status" ]; then
        return 0 # Apport service is active
    fi
    return 1 # Apport service is not active
}

# Function to apply remediation
apply_remediation() {
    echo "Disabling Apport Error Reporting Service..."
    sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
    systemctl stop apport.service
    systemctl --now disable apport.service
    echo "Apport Error Reporting Service has been disabled."
}

# Check if Apport is enabled
if check_apport_enabled; then
    echo "Audit Result:\n ** FAIL **\n - Apport Error Reporting Service is enabled."
else
    echo "Audit Result:\n ** PASS **\n - Apport Error Reporting Service is not enabled."
fi

# Check if Apport service is active
if check_apport_service_active; then
    echo "Audit Result:\n ** FAIL **\n - Apport service is active."
else
    echo "Audit Result:\n ** PASS **\n - Apport service is not active."
fi

# Prompt for remediation if either check failed
if check_apport_enabled || check_apport_service_active; then
    read -p "Do you want to apply remediation? (y/n): " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
fi
