# 3.4.3.2.3 Ensure iptables outbound and established connections are configured (Manual)
#!/bin/bash

# Function to check current iptables rules
check_iptables_rules() {
    echo "Checking iptables rules for outbound and established connections..."
    iptables_rules=$(iptables -L -v -n)
    echo "$iptables_rules"
}

# Function to audit if the required iptables rules exist
audit_iptables_rules() {
    echo "Auditing iptables rules..."
    missing_rules=()

    # Check for outbound and established connection rules in OUTPUT chain
    if ! echo "$iptables_rules" | grep -q "OUTPUT.*state NEW,ESTABLISHED.*tcp"; then
        echo "Missing rule for TCP outbound and established connections."
        missing_rules+=("tcp_outbound")
    fi

    if ! echo "$iptables_rules" | grep -q "OUTPUT.*state NEW,ESTABLISHED.*udp"; then
        echo "Missing rule for UDP outbound and established connections."
        missing_rules+=("udp_outbound")
    fi

    if ! echo "$iptables_rules" | grep -q "OUTPUT.*state NEW,ESTABLISHED.*icmp"; then
        echo "Missing rule for ICMP outbound and established connections."
        missing_rules+=("icmp_outbound")
    fi

    # Check for established connection rules in INPUT chain
    if ! echo "$iptables_rules" | grep -q "INPUT.*state ESTABLISHED.*tcp"; then
        echo "Missing rule for TCP established connections in INPUT."
        missing_rules+=("tcp_inbound")
    fi

    if ! echo "$iptables_rules" | grep -q "INPUT.*state ESTABLISHED.*udp"; then
        echo "Missing rule for UDP established connections in INPUT."
        missing_rules+=("udp_inbound")
    fi

    if ! echo "$iptables_rules" | grep -q "INPUT.*state ESTABLISHED.*icmp"; then
        echo "Missing rule for ICMP established connections in INPUT."
        missing_rules+=("icmp_inbound")
    fi

    if [ ${#missing_rules[@]} -eq 0 ]; then
        echo "All required iptables rules are in place."
        return 0
    else
        echo "Rules missing: ${missing_rules[*]}"
        return 1
    fi
}

# Function to apply missing iptables rules
apply_remediation() {
    for rule in "${missing_rules[@]}"; do
        case "$rule" in
            tcp_outbound)
                echo "Applying rule for TCP outbound and established connections..."
                iptables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
                ;;
            udp_outbound)
                echo "Applying rule for UDP outbound and established connections..."
                iptables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
                ;;
            icmp_outbound)
                echo "Applying rule for ICMP outbound and established connections..."
                iptables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
                ;;
            tcp_inbound)
                echo "Applying rule for TCP established connections in INPUT..."
                iptables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
                ;;
            udp_inbound)
                echo "Applying rule for UDP established connections in INPUT..."
                iptables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
                ;;
            icmp_inbound)
                echo "Applying rule for ICMP established connections in INPUT..."
                iptables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT
                ;;
        esac
    done

    echo "Remediation applied: iptables rules configured."
}

# Check current iptables rules
check_iptables_rules

# Audit for missing rules
if audit_iptables_rules; then
    echo "No remediation needed."
else
    # Ask the user if they want to apply the missing rules
    read -p "Would you like to apply missing iptables rules? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes made to iptables rules."
    fi
fi
