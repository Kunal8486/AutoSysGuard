# 3.4.3.3.2 Ensure ip6tables loopback traffic is configured (Automated)
#!/bin/bash

# Function to check if IPv6 is enabled
check_ipv6_enabled() {
    if grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable; then
        echo -e "\n - IPv6 is enabled on the system\n"
        return 0
    else
        echo -e "\n - IPv6 is not enabled on the system\n"
        return 1
    fi
}

# Function to check ip6tables INPUT rules for loopback and ::1
check_ip6tables_input_rules() {
    echo "Checking ip6tables INPUT rules..."
    ip6tables -L INPUT -v -n | grep -q "ACCEPT.*lo" && ip6tables -L INPUT -v -n | grep -q "DROP.*::1"
    if [ $? -eq 0 ]; then
        echo "INPUT rules are configured correctly."
        return 0
    else
        echo "INPUT rules are missing or not configured correctly."
        return 1
    fi
}

# Function to check ip6tables OUTPUT rules for loopback
check_ip6tables_output_rules() {
    echo "Checking ip6tables OUTPUT rules..."
    ip6tables -L OUTPUT -v -n | grep -q "ACCEPT.*lo"
    if [ $? -eq 0 ]; then
        echo "OUTPUT rules are configured correctly."
        return 0
    else
        echo "OUTPUT rules are missing or not configured correctly."
        return 1
    fi
}

# Function to apply the ip6tables loopback rules
apply_remediation() {
    echo "Applying remediation: Configuring ip6tables loopback rules..."
    
    # Add the required rules
    ip6tables -A INPUT -i lo -j ACCEPT
    ip6tables -A OUTPUT -o lo -j ACCEPT
    ip6tables -A INPUT -s ::1 -j DROP

    echo "Remediation applied: ip6tables loopback rules configured."
}

# Function to disable IPv6
disable_ipv6() {
    echo "Disabling IPv6 on the system..."
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    echo "IPv6 has been disabled."
}

# Perform IPv6 audit
echo "Performing IPv6 audit..."
if check_ipv6_enabled; then
    echo "No remediation needed for IPv6."
else
    echo "IPv6 is not enabled."

    # Ask the user if they want to apply remediation for disabling IPv6
    read -p "Would you like to disable IPv6 as part of remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        disable_ipv6
    else
        echo "No changes made to IPv6 configuration."
    fi
fi

# Perform ip6tables audit
echo "Performing ip6tables audit..."
input_rules_ok=false
output_rules_ok=false

if check_ip6tables_input_rules; then
    input_rules_ok=true
fi

if check_ip6tables_output_rules; then
    output_rules_ok=true
fi

# Ask the user if they want to apply ip6tables remediation if rules are missing
if [[ "$input_rules_ok" == false || "$output_rules_ok" == false ]]; then
    read -p "Would you like to apply ip6tables remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes made to ip6tables configuration."
    fi
else
    echo "No remediation needed for ip6tables."
fi
