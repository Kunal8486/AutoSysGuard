#!/bin/bash

# Function to check if IPv6 is enabled
check_ipv6_enabled() {
    if grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable; then
        echo -e "\n - IPv6 is enabled\n"
        return 0
    else
        echo -e "\n - IPv6 is not enabled\n"
        return 1
    fi
}

# Function to apply the remediation (disabling IPv6)
apply_remediation() {
    echo "Applying remediation: Disabling IPv6..."
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    echo "Remediation applied: IPv6 is now disabled."
}

# Perform the audit
echo "Performing IPv6 audit..."
if check_ipv6_enabled; then
    echo "No remediation needed. IPv6 is already enabled."
else
    echo "IPv6 is not enabled."

    # Ask the user if they want to apply the remediation
    read -p "Would you like to disable IPv6 as part of remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes were made. Exiting."
    fi
fi
