#!/bin/bash

# Function to run the audit
run_audit() {
    echo "Running audit for nftables base chains and loopback configuration..."

    audit_result="PASS"

    # Check input base chain
    echo "Checking input base chain..."
    input_base_chain=$( [ -n "$(grep -E '^\s*include' /etc/nftables.conf)" ] && awk '/hook input/,/}/' $(awk '$1 ~ /^\s*include/ { gsub("\"","",$2);print $2 }' /etc/nftables.conf) )
    
    if [[ "$input_base_chain" == *"policy drop"* && "$input_base_chain" == *"iif \"lo\" accept"* && "$input_base_chain" == *"ip saddr 127.0.0.0/8 counter drop"* ]]; then
        echo " - Input base chain configuration is correct."
    else
        echo " - ** FAIL ** Input base chain configuration is incorrect."
        audit_result="FAIL"
    fi

    # Check forward base chain
    echo "Checking forward base chain..."
    forward_base_chain=$( [ -n "$(grep -E '^\s*include' /etc/nftables.conf)" ] && awk '/hook forward/,/}/' $(awk '$1 ~ /^\s*include/ { gsub("\"","",$2);print $2 }' /etc/nftables.conf) )
    
    if [[ "$forward_base_chain" == *"policy drop"* ]]; then
        echo " - Forward base chain configuration is correct."
    else
        echo " - ** FAIL ** Forward base chain configuration is incorrect."
        audit_result="FAIL"
    fi

    # Check output base chain
    echo "Checking output base chain..."
    output_base_chain=$( [ -n "$(grep -E '^\s*include' /etc/nftables.conf)" ] && awk '/hook output/,/}/' $(awk '$1 ~ /^\s*include/ { gsub("\"","",$2);print $2 }' /etc/nftables.conf) )
    
    if [[ "$output_base_chain" == *"policy drop"* && "$output_base_chain" == *"ip protocol tcp ct state established,related,new accept"* ]]; then
        echo " - Output base chain configuration is correct."
    else
        echo " - ** FAIL ** Output base chain configuration is incorrect."
        audit_result="FAIL"
    fi

    # Print audit result
    echo ""
    if [ "$audit_result" = "FAIL" ]; then
        echo "- Audit Result: ** FAIL **"
    else
        echo "- Audit Result: ** PASS **"
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Update /etc/nftables.conf to include nftables rules file
    if ! grep -q 'include "/etc/nftables.rules"' /etc/nftables.conf; then
        echo 'include "/etc/nftables.rules"' | sudo tee -a /etc/nftables.conf
        echo " - Added line to include /etc/nftables.rules in /etc/nftables.conf."
    else
        echo " - /etc/nftables.rules is already included in /etc/nftables.conf."
    fi

    # Create or update /etc/nftables.rules with correct configuration
    sudo tee /etc/nftables.rules > /dev/null <<EOF
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Ensure loopback traffic is configured
        iif "lo" accept
        ip saddr 127.0.0.0/8 counter packets 0 bytes 0 drop
        ip6 saddr ::1 counter packets 0 bytes 0 drop
        
        # Ensure established connections are configured
        ip protocol tcp ct state established accept
        ip protocol udp ct state established accept
        ip protocol icmp ct state established accept
        
        # Accept port 22(SSH) traffic
        tcp dport ssh accept
        
        # Accept ICMP and IGMP from anywhere
        icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept
    }

    chain forward {
        type filter hook forward priority 0; policy drop;
    }

    chain output {
        type filter hook output priority 0; policy drop;
        
        # Ensure outbound and established connections are configured
        ip protocol tcp ct state established,related,new accept
        ip protocol udp ct state established,related,new accept
        ip protocol icmp ct state established,related,new accept
    }
}
EOF

    echo "Remediation applied. Re-running the audit..."
}

# Run the initial audit
run_audit

# Check if audit failed, then ask user for remediation
if [ "$audit_result" = "FAIL" ]; then
    read -p "Do you want to apply remediation? (y/n): " apply_fix
    if [ "$apply_fix" = "y" ]; then
        apply_remediation
        
        # Re-run audit after remediation
        run_audit
    else
        echo "Remediation not applied."
    fi
else
    echo "No remediation needed. Audit passed."
fi
