# 3.3.1 Ensure source routed packets are not accepted (Automated)
#!/usr/bin/env bash

# Define the kernel parameters and expected values
declare -A params=(
    ["net.ipv4.conf.all.accept_source_route"]="0"
    ["net.ipv4.conf.default.accept_source_route"]="0"
    ["net.ipv6.conf.all.accept_source_route"]="0"
    ["net.ipv6.conf.default.accept_source_route"]="0"
)

# Initialize output variables
l_output=""
l_output2=""

# Function to check the kernel parameters
kernel_parameter_chk() {
    local l_kpname="$1"
    local l_kpvalue="$2"
    
    # Check running configuration
    l_krp="$(sysctl -n "$l_kpname")" # Using -n to get only the value
    if [ "$l_krp" = "$l_kpvalue" ]; then
        l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
    else
        l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
    fi

    # Check if the setting exists in the configuration files
    local found=false
    for conf_file in /etc/sysctl.conf /etc/sysctl.d/*.conf; do
        if [ -f "$conf_file" ]; then
            if grep -q -E "^\s*$l_kpname\s*=" "$conf_file"; then
                found=true
                break
            fi
        fi
    done

    if ! $found; then
        l_output2="$l_output2\n - \"$l_kpname\" is not set in any included file\n ** Note: \"$l_kpname\" may be set in a file that's ignored by the load procedure **\n"
    fi
}

# Iterate through parameters and check their status
for param in "${!params[@]}"; do
    kernel_parameter_chk "$param" "${params[$param]}"
done

# Display the audit result
if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
    
    # Prompt user for remediation
    read -p "Do you want to apply remediation? (y/n): " apply_remediation

    if [[ "$apply_remediation" =~ ^[Yy]$ ]]; then
        # Create or append the configuration file for IPv4 parameters
        {
            echo -e "\nApplying remediation for IPv4 parameters..."
            echo "net.ipv4.conf.all.accept_source_route=0" | sudo tee -a /etc/sysctl.d/60-netipv4_sysctl.conf
            echo "net.ipv4.conf.default.accept_source_route=0" | sudo tee -a /etc/sysctl.d/60-netipv4_sysctl.conf
            sudo sysctl -w net.ipv4.conf.all.accept_source_route=0
            sudo sysctl -w net.ipv4.conf.default.accept_source_route=0
            sudo sysctl -w net.ipv4.route.flush=1
        }

        # Apply remediation for IPv6 if applicable
        if sysctl -n net.ipv6.conf.all.accept_source_route &>/dev/null; then
            {
                echo -e "\nApplying remediation for IPv6 parameters..."
                echo "net.ipv6.conf.all.accept_source_route=0" | sudo tee -a /etc/sysctl.d/60-netipv6_sysctl.conf
                echo "net.ipv6.conf.default.accept_source_route=0" | sudo tee -a /etc/sysctl.d/60-netipv6_sysctl.conf
                sudo sysctl -w net.ipv6.conf.all.accept_source_route=0
                sudo sysctl -w net.ipv6.conf.default.accept_source_route=0
                sudo sysctl -w net.ipv6.route.flush=1
            }
        fi

        echo -e "\n- Remediation applied successfully."
    else
        echo -e "\n- No changes were made."
    fi
fi
