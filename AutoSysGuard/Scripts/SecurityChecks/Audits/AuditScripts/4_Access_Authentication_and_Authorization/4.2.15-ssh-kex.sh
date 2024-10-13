#!/bin/bash

# Define weak key exchange algorithms
weak_algorithms=("diffie-hellman-group1-sha1" "diffie-hellman-group14-sha1" "diffie-hellman-group-exchange-sha1")

# Function to audit the KexAlgorithms setting
audit_kex_algorithms() {
    # Get the current KexAlgorithms setting from sshd
    current_setting=$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep kexalgorithms)

    # Check if current setting contains any weak algorithms
    echo "Current KexAlgorithms setting: $current_setting"
    for weak_algo in "${weak_algorithms[@]}"; do
        if echo "$current_setting" | grep -qi "$weak_algo"; then
            echo "Audit Failed: Weak Key Exchange Algorithm found: $weak_algo"
            return 1
        fi
    done

    echo "Audit Passed: No weak Key Exchange Algorithms found."
    return 0
}

# Function to apply remediation
remediate_kex_algorithms() {
    # Define approved key exchange algorithms
    approved_algorithms="curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256"
    
    # Set the KexAlgorithms in the sshd_config file
    if grep -q '^\h*KexAlgorithms' /etc/ssh/sshd_config; then
        # If KexAlgorithms exists, change it
        sed -i "s/^\h*KexAlgorithms.*/KexAlgorithms $approved_algorithms/" /etc/ssh/sshd_config
    else
        # If KexAlgorithms does not exist, add it
        echo "KexAlgorithms $approved_algorithms" >> /etc/ssh/sshd_config
    fi
    echo "Remediation applied: KexAlgorithms set to approved algorithms."
}

# Main script execution
audit_kex_algorithms
if [ $? -ne 0 ]; then
    read -p "Do you want to apply remediation? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        remediate_kex_algorithms
    else
        echo "No changes were made."
    fi
else
    echo "No remediation needed."
fi
