#!/bin/bash

# Function to check current iptables rules
check_iptables_rules() {
    echo "Checking current iptables rules for loopback traffic..."
    iptables_rules_input=$(iptables -L INPUT -v -n)
    iptables_rules_output=$(iptables -L OUTPUT -v -n)
    echo "INPUT chain rules:"
    echo "$iptables_rules_input"
    echo "OUTPUT chain rules:"
    echo "$iptables_rules_output"
}

# Function to audit the loopback rules in iptables
audit_loopback_rules() {
    echo "Auditing loopback rules in iptables..."

    # Check for loopback rule in INPUT chain
    if ! echo "$iptables_rules_input" | grep -q "ACCEPT.*lo"; then
        echo "Missing rule for loopback traffic in INPUT chain."
        missing_rules+=("input_lo_accept")
    fi

    # Check for drop rule on 127.0.0.0/8 in INPUT chain
    if ! echo "$iptables_rules_input" | grep -q "DROP.*127.0.0.0/8"; then
        echo "Missing rule to drop traffic from 127.0.0.0/8 in INPUT chain."
        missing_rules+=("input_drop_127")
    fi

    # Check for loopback rule in OUTPUT chain
    if ! echo "$iptables_rules_output" | grep -q "ACCEPT.*lo"; then
        echo "Missing rule for loopback traffic in OUTPUT chain."
        missing_rules+=("output_lo_accept")
    fi

    if [ ${#missing_rules[@]} -eq 0 ]; then
        echo "All required loopback rules are in place."
        return 0
    else
        echo "Rules missing: ${missing_rules[*]}"
        return 1
    fi
}

# Function to apply missing iptables loopback rules
apply_remediation() {
    for rule in "${missing_rules[@]}"; do
        case "$rule" in
            input_lo_accept)
                echo "Applying rule to accept loopback traffic in INPUT chain..."
                iptables -A INPUT -i lo -j ACCEPT
                ;;
            input_drop_127)
                echo "Applying rule to drop traffic from 127.0.0.0/8 in INPUT chain..."
                iptables -A INPUT -s 127.0.0.0/8 -j DROP
                ;;
            output_lo_accept)
                echo "Applying rule to accept loopback traffic in OUTPUT chain..."
                iptables -A OUTPUT -o lo -j ACCEPT
                ;;
        esac
    done
    echo "Remediation applied: iptables loopback rules configured."
}

# Check current iptables rules
check_iptables_rules

# Audit for missing loopback rules
missing_rules=()
if audit_loopback_rules; then
    echo "No remediation needed."
else
    # Ask the user if they want to apply the missing rules
    read -p "Would you like to apply the missing iptables rules? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes made to iptables rules."
    fi
fi
