#!/bin/bash

# Define weak ciphers
weak_ciphers=(
    "3des-cbc"
    "aes128-cbc"
    "aes192-cbc"
    "aes256-cbc"
    "rijndael-cbc@lysator.liu.se"
)

# Function to audit the Ciphers setting
audit_ciphers() {
    # Get the current Ciphers setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep "ciphers")

    # Check if current setting contains any weak ciphers
    echo "Current Ciphers setting: $current_setting"
    for weak_cipher in "${weak_ciphers[@]}"; do
        if echo "$current_setting" | grep -qi "$weak_cipher"; then
            echo "Audit Failed: Weak Cipher found: $weak_cipher"
            return 1
        fi
    done

    echo "Audit Passed: No weak Ciphers found."
    return 0
}

# Function to apply remediation
remediate_ciphers() {
    # Define approved ciphers
    approved_ciphers="chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
    
    # Set the Ciphers in the sshd_config file
    if grep -q '^\h*Ciphers' /etc/ssh/sshd_config; then
        # If Ciphers exists, change it
        sed -i "s/^\h*Ciphers.*/Ciphers $approved_ciphers/" /etc/ssh/sshd_config
    else
        # If Ciphers does not exist, add it
        echo "Ciphers $approved_ciphers" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: Ciphers set to approved Ciphers."
}

# Main script execution
audit_ciphers
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_ciphers
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
