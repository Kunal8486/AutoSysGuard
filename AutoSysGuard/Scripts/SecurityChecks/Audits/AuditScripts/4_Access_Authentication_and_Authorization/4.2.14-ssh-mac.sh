#!/bin/bash

# Define weak MAC algorithms
weak_mac_algorithms=(
    "hmac-md5"
    "hmac-md5-96"
    "hmac-ripemd160"
    "hmac-sha1"
    "hmac-sha1-96"
    "umac-64@openssh.com"
    "hmac-md5-etm@openssh.com"
    "hmac-md5-96-etm@openssh.com"
    "hmac-ripemd160-etm@openssh.com"
    "hmac-sha1-etm@openssh.com"
    "hmac-sha1-96-etm@openssh.com"
    "umac-64-etm@openssh.com"
)

# Function to audit the MACs setting
audit_macs() {
    # Get the current MACs setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -i "MACs")

    # Check if current setting contains any weak MAC algorithms
    echo "Current MACs setting: $current_setting"
    for weak_mac in "${weak_mac_algorithms[@]}"; do
        if echo "$current_setting" | grep -qi "$weak_mac"; then
            echo "Audit Failed: Weak MAC Algorithm found: $weak_mac"
            return 1
        fi
    done

    echo "Audit Passed: No weak MAC Algorithms found."
    return 0
}

# Function to apply remediation
remediate_macs() {
    # Define approved MAC algorithms
    approved_macs="hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128-etm@openssh.com,umac-128@openssh.com"
    
    # Set the MACs in the sshd_config file
    if grep -q '^\h*MACs' /etc/ssh/sshd_config; then
        # If MACs exists, change it
        sed -i "s/^\h*MACs.*/MACs $approved_macs/" /etc/ssh/sshd_config
    else
        # If MACs does not exist, add it
        echo "MACs $approved_macs" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: MACs set to approved MAC algorithms."
}

# Main script execution
audit_macs
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_macs
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
