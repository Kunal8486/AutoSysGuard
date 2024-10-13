# 3.3.2 Ensure ICMP redirects are not accepted (Automated)
#!/usr/bin/env bash

# Initialize output variables
l_output=""
l_output2=""

# List of kernel parameters to check
a_parlist=(
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv6.conf.all.accept_redirects=0"
    "net.ipv6.conf.default.accept_redirects=0"
)

# Function to check the kernel parameters
kernel_parameter_chk() {
    local l_kpname="$1"
    local l_kpvalue="$2"
    
    # Check running configuration
    l_krp="$(sysctl -n "$l_kpname")" # Get the current value without the key
    if [ "$l_krp" = "$l_kpvalue" ]; then
        l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
    else
        l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
    fi

    # Check for durable setting (files)
    local A_out=()
    local conf_file

    # Gather all configuration files
    while read -r conf_file; do
        if [ -n "$conf_file" ]; then
            l_kpar="$(grep -Po "^\s*$l_kpname\b" "$conf_file" | xargs)"
            if [[ "$l_kpar" = "$l_kpname" ]]; then
                A_out+=("$conf_file")
            fi
        fi
    done < <(grep -rl "^$l_kpname" /etc/sysctl.conf /etc/sysctl.d/*.conf)

    if [ ${#A_out[@]} -gt 0 ]; then
        for file in "${A_out[@]}"; do
            l_fkpvalue="$(grep -Po "^\s*$l_kpname\s*=\s*\S+" "$file" | awk -F= '{print $2}' | xargs)"
            if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
                l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in \"$file\""
            else
                l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in \"$file\" and should have a value of: \"$l_kpvalue\""
            fi
        done
    else
        l_output2="$l_output2\n - \"$l_kpname\" is not set in any included file\n ** Note: \"$l_kpname\" may be set in a file that's ignored by the load procedure **\n"
    fi
}

# Iterate through parameters and check their status
for entry in "${a_parlist[@]}"; do
    l_kpname="${entry%%=*}"
    l_kpvalue="${entry##*=}"
    
    if [[ "$l_kpname" == net.ipv6.* ]] && ! grep -q '^net.ipv6' /proc/net/ip6_tables_targets; then
        l_output="$l_output\n - IPv6 is disabled on the system, \"$l_kpname\" is not applicable"
    else
        kernel_parameter_chk "$l_kpname" "$l_kpvalue"
    fi
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
        # Apply remediation for IPv4 parameters
        {
            echo -e "\nApplying remediation for IPv4 parameters..."
            echo "net.ipv4.conf.all.accept_redirects=0" | sudo tee -a /etc/sysctl.d/60-netipv4_sysctl.conf
            echo "net.ipv4.conf.default.accept_redirects=0" | sudo tee -a /etc/sysctl.d/60-netipv4_sysctl.conf
            sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
            sudo sysctl -w net.ipv4.conf.default.accept_redirects=0
            sudo sysctl -w net.ipv4.route.flush=1
        }

        # Apply remediation for IPv6 if applicable
        if grep -q '^net.ipv6' /proc/net/ip6_tables_targets; then
            {
                echo -e "\nApplying remediation for IPv6 parameters..."
                echo "net.ipv6.conf.all.accept_redirects=0" | sudo tee -a /etc/sysctl.d/60-netipv6_sysctl.conf
                echo "net.ipv6.conf.default.accept_redirects=0" | sudo tee -a /etc/sysctl.d/60-netipv6_sysctl.conf
                sudo sysctl -w net.ipv6.conf.all.accept_redirects=0
                sudo sysctl -w net.ipv6.conf.default.accept_redirects=0
                sudo sysctl -w net.ipv6.route.flush=1
            }
        fi

        echo -e "\n- Remediation applied successfully."
    else
        echo -e "\n- No changes were made."
    fi
fi
