#!/bin/bash

# Function to audit established incoming connections in the input chain
audit_established_input() {
    echo "Auditing established incoming connections in the input chain..."
    result=$(nft list ruleset | awk '/hook input/,/}/' | grep -E 'ip protocol (tcp|udp|icmp) ct state established')

    if [[ -n "$result" ]]; then
        echo "Established incoming connections are configured correctly."
        return 0
    else
        echo "Established incoming connections are NOT configured correctly."
        return 1
    fi
}

# Function to audit new and established outbound connections in the output chain
audit_outbound_output() {
    echo "Auditing new and established outbound connections in the output chain..."
    result=$(nft list ruleset | awk '/hook output/,/}/' | grep -E 'ip protocol (tcp|udp|icmp) ct state (new|related|established)')

    if [[ -n "$result" ]]; then
        echo "New and established outbound connections are configured correctly."
        return 0
    else
        echo "New and established outbound connections are NOT configured correctly."
        return 1
    fi
}

# Function to apply remediation for outbound and established connections
apply_remediation() {
    echo "Applying remediation for outbound and established connections..."

    # Add rules to allow established connections in input chain
    nft add rule inet filter input ip protocol tcp ct state established accept
    nft add rule inet filter input ip protocol udp ct state established accept
    nft add rule inet filter input ip protocol icmp ct state established accept

    # Add rules to allow new and established connections in output chain
    nft add rule inet filter output ip protocol tcp ct state new,related,established accept
    nft add rule inet filter output ip protocol udp ct state new,related,established accept
    nft add rule inet filter output ip protocol icmp ct state new,related,established accept

    if [[ $? -eq 0 ]]; then
        echo "Remediation applied successfully."
    else
        echo "Failed to apply remediation. Please check your nftables configuration."
    fi
}

# Audit the input and output chains
audit_input=0
audit_output=0

audit_established_input
audit_input=$?
echo ""
audit_outbound_output
audit_output=$?
echo ""

# Check if any chain needs remediation
if [[ $audit_input -eq 1 || $audit_output -eq 1 ]]; then
    echo "One or more chains need remediation."

    # Ask user for permission to apply remediation
    read -p "Would you like to apply the rules for outbound and established connections? (y/n): " choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        apply_remediation
    else
        echo "Remediation skipped."
    fi
else
    echo "All rules for outbound and established connections are configured correctly. No remediation needed."
fi
