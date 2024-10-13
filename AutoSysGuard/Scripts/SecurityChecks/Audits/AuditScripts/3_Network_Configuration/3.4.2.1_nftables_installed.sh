# 3.4.2.1 Ensure nftables is installed (Automated)
#!/usr/bin/env bash

# Function to perform the audit
perform_audit() {
    # Check if nftables is installed
    if dpkg-query -s nftables | grep -q 'Status: install ok installed'; then
        echo -e "\n- Audit Passed -\n- nftables is installed.\n"
        return 0
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n- nftables is not installed.\n"
        return 1
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Installing nftables..."
    sudo apt install -y nftables
    if [[ $? -eq 0 ]]; then
        echo "nftables installed successfully."
    else
        echo "Failed to install nftables."
    fi
}

# Main script execution
perform_audit
audit_result=$?

# If audit fails, prompt for remediation
if [[ $audit_result -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
fi
