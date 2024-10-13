# 3.4.3.3.1 Ensure ip6tables default deny firewall policy (Automated)
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

# Function to check ip6tables policy for INPUT, OUTPUT, and FORWARD chains
check_ip6tables_policies() {
    echo "Checking ip6tables policies for INPUT, OUTPUT, and FORWARD chains..."
    input_policy=$(ip6tables -L INPUT --line-numbers -n | grep 'Chain INPUT (policy')
    forward_policy=$(ip6tables -L FORWARD --line-numbers -n | grep 'Chain FORWARD (policy')
    output_policy=$(ip6tables -L OUTPUT --line-numbers -n | grep 'Chain OUTPUT (policy')

    echo "Current Policies:"
    echo "$input_policy"
    echo "$forward_policy"
    echo "$output_policy"

    # Check if all policies are set to DROP or REJECT
    if [[ "$input_policy" == *"(policy DROP)"* || "$input_policy" == *"(policy REJECT)"* ]] &&
       [[ "$forward_policy" == *"(policy DROP)"* || "$forward_policy" == *"(policy REJECT)"* ]] &&
       [[ "$output_policy" == *"(policy DROP)"* || "$output_policy" == *"(policy REJECT)"* ]]; then
        echo "All ip6tables policies are set correctly (DROP or REJECT)."
        return 0
    else
        echo "Some ip6tables policies are not set to DROP or REJECT."
        return 1
    fi
}

# Function to apply remediation (set default policies to DROP)
apply_remediation() {
    echo "Applying remediation: Setting default policies to DROP..."
    
    # Set default DROP policy for INPUT, OUTPUT, and FORWARD
    ip6tables -P INPUT DROP
    ip6tables -P OUTPUT DROP
    ip6tables -P FORWARD DROP

    echo "Remediation applied: Default DROP policy configured for all chains."
}

# Perform IPv6 audit
echo "Performing IPv6 audit..."
if check_ipv6_enabled; then
    echo "IPv6 is enabled on the system."
else
    echo "IPv6 is not enabled. No further actions required."
    exit 0
fi

# Perform ip6tables audit
echo "Performing ip6tables policy audit..."
if check_ip6tables_policies; then
    echo "No remediation needed for ip6tables policies."
else
    # Ask the user if they want to apply remediation
    read -p "Would you like to set default DROP policy for all chains? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes made to ip6tables policies."
    fi
fi
