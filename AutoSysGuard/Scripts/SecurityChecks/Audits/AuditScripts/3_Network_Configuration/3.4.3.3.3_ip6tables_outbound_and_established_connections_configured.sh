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

# Function to check ip6tables rules
check_ip6tables_rules() {
    echo "Checking ip6tables rules for outbound and established connections..."
    ip6tables -L -v -n
    echo -e "\nVerify the rules listed above match the site policy.\n"
    # In a real scenario, you would implement more logic here to check rules.
}

# Function to apply remediation (adding ip6tables rules)
apply_remediation() {
    echo "Applying remediation: Configuring ip6tables rules..."
    
    ip6tables -A OUTPUT -p tcp -m state --state NEW,ESTABLISHED -j ACCEPT
    ip6tables -A OUTPUT -p udp -m state --state NEW,ESTABLISHED -j ACCEPT
    ip6tables -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED -j ACCEPT
    ip6tables -A INPUT -p tcp -m state --state ESTABLISHED -j ACCEPT
    ip6tables -A INPUT -p udp -m state --state ESTABLISHED -j ACCEPT
    ip6tables -A INPUT -p icmp -m state --state ESTABLISHED -j ACCEPT

    echo "Remediation applied: ip6tables rules configured."
}

# Function to disable IPv6 if necessary
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

    # Ask the user if they want to apply remediation
    read -p "Would you like to disable IPv6 as part of remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        disable_ipv6
    else
        echo "No changes made to IPv6 configuration."
    fi
fi

# Perform ip6tables audit
echo "Performing ip6tables audit..."
check_ip6tables_rules

# Ask the user if they want to apply ip6tables remediation
read -p "Would you like to apply ip6tables remediation? (y/n): " user_input

if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
    apply_remediation
else
    echo "No changes made to ip6tables configuration."
fi

