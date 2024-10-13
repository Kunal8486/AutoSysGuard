# 3.3.7 Ensure Reverse Path Filtering is enabled (Automated)
#!/usr/bin/env bash

# Initialize output variables
l_output=""
l_output2=""
a_parlist=("net.ipv4.conf.all.rp_filter=1" "net.ipv4.conf.default.rp_filter=1")

# Function to check kernel parameters
kernel_parameter_chk() {
    l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration
    if [ "$l_krp" = "$l_kpvalue" ]; then
        l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
    else
        l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
    fi

    # Check durable setting (files)
    unset A_out
    declare -A A_out
    
    while read -r l_out; do
        if [ -n "$l_out" ]; then
            if [[ $l_out =~ ^\s*# ]]; then
                l_file="${l_out//# /}"
            else
                l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
                [ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
            fi
        fi
    done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

    if (( ${#A_out[@]} > 0 )); then
        while IFS="=" read -r l_fkpname l_fkpvalue; do
            l_fkpname="${l_fkpname// /}"; l_fkpvalue="${l_fkpvalue// /}"
            if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
                l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\"\n"
            else
                l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_kpvalue\"\n"
            fi
        done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
    else
        l_output2="$l_output2\n - \"$l_kpname\" is not set in an included file\n ** Note: \"$l_kpname\" may be set in a file that's ignored by load procedure **\n"
    fi
}

# Loop through the parameter list and check each parameter
while IFS="=" read -r l_kpname l_kpvalue; do
    l_kpname="${l_kpname// /}"; l_kpvalue="${l_kpvalue// /}"
    kernel_parameter_chk
done < <(printf '%s\n' "${a_parlist[@]}")

# Output the audit results
if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"

    # Ask user for remediation
    read -p "Do you want to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        echo "Setting kernel parameters..."
        
        # Set the kernel parameters temporarily
        sysctl -w net.ipv4.conf.all.rp_filter=1
        sysctl -w net.ipv4.conf.default.rp_filter=1
        
        # Check if parameters are in the config file
        if grep -q "^net.ipv4.conf.all.rp_filter" /etc/sysctl.d/60-netipv4_sysctl.conf; then
            sed -i "s/^net.ipv4.conf.all.rp_filter=.*/net.ipv4.conf.all.rp_filter=1/" /etc/sysctl.d/60-netipv4_sysctl.conf
        else
            echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.d/60-netipv4_sysctl.conf
        fi

        if grep -q "^net.ipv4.conf.default.rp_filter" /etc/sysctl.d/60-netipv4_sysctl.conf; then
            sed -i "s/^net.ipv4.conf.default.rp_filter=.*/net.ipv4.conf.default.rp_filter=1/" /etc/sysctl.d/60-netipv4_sysctl.conf
        else
            echo "net.ipv4.conf.default.rp_filter=1" >> /etc/sysctl.d/60-netipv4_sysctl.conf
        fi

        # Flush the routes to apply the settings
        sysctl -w net.ipv4.route.flush=1
        
        echo "Remediation applied. Kernel parameters updated and saved."
    else
        echo "No changes were made."
    fi
fi
