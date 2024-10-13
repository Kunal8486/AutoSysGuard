# 3.4.3.2.1 Ensure iptables default deny firewall policy (Automated)
#!/bin/bash

# Function to check current iptables chain policies
check_policies() {
    echo "Checking current iptables policies..."

    input_policy=$(iptables -L INPUT -n | grep 'Chain INPUT' | awk '{print $4}')
    output_policy=$(iptables -L OUTPUT -n | grep 'Chain OUTPUT' | awk '{print $4}')
    forward_policy=$(iptables -L FORWARD -n | grep 'Chain FORWARD' | awk '{print $4}')

    echo "INPUT chain policy: $input_policy"
    echo "OUTPUT chain policy: $output_policy"
    echo "FORWARD chain policy: $forward_policy"
}

# Function to audit policies for INPUT, OUTPUT, and FORWARD chains
audit_policies() {
    echo "Auditing iptables chain policies..."
    issues=()

    if [[ "$input_policy" != "DROP" && "$input_policy" != "REJECT" ]]; then
        echo "INPUT chain policy is not set to DROP or REJECT."
        issues+=("input")
    fi

    if [[ "$output_policy" != "DROP" && "$output_policy" != "REJECT" ]]; then
        echo "OUTPUT chain policy is not set to DROP or REJECT."
        issues+=("output")
    fi

    if [[ "$forward_policy" != "DROP" && "$forward_policy" != "REJECT" ]]; then
        echo "FORWARD chain policy is not set to DROP or REJECT."
        issues+=("forward")
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        echo "All chain policies are correctly set to DROP or REJECT."
        return 0
    else
        echo "Issues found with chain policies: ${issues[*]}"
        return 1
    fi
}

# Function to apply the default DROP policy
apply_remediation() {
    for chain in "${issues[@]}"; do
        case "$chain" in
            input)
                echo "Applying DROP policy to INPUT chain..."
                iptables -P INPUT DROP
                ;;
            output)
                echo "Applying DROP policy to OUTPUT chain..."
                iptables -P OUTPUT DROP
                ;;
            forward)
                echo "Applying DROP policy to FORWARD chain..."
                iptables -P FORWARD DROP
                ;;
        esac
    done
    echo "Remediation applied: iptables default policies set to DROP."
}

# Check current policies
check_policies

# Audit the chain policies
if audit_policies; then
    echo "No remediation needed."
else
    # Ask the user if they want to apply the missing rules
    read -p "Would you like to apply the missing iptables policies? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No changes made to iptables policies."
    fi
fi
