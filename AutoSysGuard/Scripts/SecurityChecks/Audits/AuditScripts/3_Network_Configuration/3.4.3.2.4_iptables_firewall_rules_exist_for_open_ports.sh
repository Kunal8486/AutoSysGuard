# 3.4.3.2.4 Ensure iptables firewall rules exist for all open ports (Automated)
#!/bin/bash

# Function to list open ports using ss
check_open_ports() {
    echo "Checking open ports..."
    ss_output=$(ss -4tuln)
    echo "$ss_output"
}

# Function to check firewall rules in iptables
check_firewall_rules() {
    echo "Checking iptables firewall rules for INPUT chain..."
    iptables_input_rules=$(iptables -L INPUT -v -n)
    echo "$iptables_input_rules"
}

# Function to check if each open port has a corresponding firewall rule
audit_firewall_rules() {
    open_ports=$(ss -4tuln | awk '/LISTEN/ {print $5}' | cut -d ':' -f2)
    missing_rules=()

    echo "Auditing firewall rules for open ports..."
    for port in $open_ports; do
        if ! echo "$iptables_input_rules" | grep -q "dpt:$port"; then
            echo "No firewall rule found for port $port"
            missing_rules+=("$port")
        else
            echo "Firewall rule exists for port $port"
        fi
    done

    if [ ${#missing_rules[@]} -eq 0 ]; then
        echo "All open ports have corresponding firewall rules."
        return 0
    else
        echo "Ports missing firewall rules: ${missing_rules[*]}"
        return 1
    fi
}

# Function to apply remediation for missing firewall rules
apply_remediation() {
    protocol=$1
    port=$2
    echo "Applying remediation: Adding firewall rule for port $port"
    iptables -A INPUT -p "$protocol" --dport "$port" -m state --state NEW -j ACCEPT
    echo "Firewall rule added for port $port."
}

# Perform open ports and firewall rules audit
check_open_ports
check_firewall_rules

# Audit for missing firewall rules
if audit_firewall_rules; then
    echo "No remediation needed."
else
    # Ask the user if they want to apply firewall rules for each missing port
    for port in "${missing_rules[@]}"; do
        read -p "Would you like to add a firewall rule for port $port? (y/n): " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            protocol=$(ss -4tuln | awk -v port=$port '$5 ~ ":" port {print $1}')
            apply_remediation "$protocol" "$port"
        else
            echo "No firewall rule added for port $port."
        fi
    done
fi
