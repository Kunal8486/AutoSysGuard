# 3.4.3.3.4 Ensure ip6tables firewall rules exist for all open ports (Automated)
#!/bin/bash

# Function to check if a rule exists for the specified port
check_rule_for_port() {
    local port=$1
    local protocol=$2

    if ip6tables -L INPUT -v -n | grep -q "dpt:$port"; then
        return 0  # Rule exists
    else
        return 1  # Rule does not exist
    fi
}

# Function to apply remediation for a specific port
apply_remediation() {
    local port=$1
    local protocol=$2

    read -p "Would you like to apply the remediation for port $port with protocol $protocol? (y/n): " response
    if [[ "$response" == "y" ]]; then
        ip6tables -A INPUT -p "$protocol" --dport "$port" -m state --state NEW -j ACCEPT
        if [ $? -eq 0 ]; then
            echo "Remediation applied for port $port with protocol $protocol."
        else
            echo "Failed to apply remediation for port $port with protocol $protocol."
        fi
    else
        echo "Remediation skipped for port $port with protocol $protocol."
    fi
}

# Check for open ports
echo "Checking open ports..."
open_ports=$(ss -6tuln | awk 'NR>1 {print $1, $5}' | sed 's/::.*://g; s/:/ /;')

if [[ -z "$open_ports" ]]; then
    echo "No open ports found."
    exit 0
fi

# Loop through open ports and check for corresponding firewall rules
while read -r line; do
    protocol=$(echo "$line" | awk '{print $1}')
    port=$(echo "$line" | awk '{print $2}')
    
    # Determine the protocol (tcp or udp) for the remediation
    if [[ "$protocol" == "tcp" ]]; then
        proto="tcp"
    elif [[ "$protocol" == "udp" ]]; then
        proto="udp"
    else
        continue
    fi
    
    echo "Checking firewall rules for $proto port $port..."
    
    # Check if a rule exists for this port
    if ! check_rule_for_port "$port" "$proto"; then
        echo "No firewall rule found for $proto port $port."
        apply_remediation "$port" "$proto"
    else
        echo "Firewall rule exists for $proto port $port."
    fi

done <<< "$open_ports"

echo "Audit complete."
