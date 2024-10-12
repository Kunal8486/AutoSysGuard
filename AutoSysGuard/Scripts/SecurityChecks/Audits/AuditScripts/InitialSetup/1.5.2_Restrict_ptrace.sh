#!/usr/bin/env bash

# Initialize variables
l_output=""
l_output2=""
l_kpname="kernel.yama.ptrace_scope"
l_kpvalue="1"

# Function to check kernel parameter
kernel_parameter_chk() {
    l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration
    if [ "$l_krp" = "$l_kpvalue" ]; then
        l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
    else
        l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
    fi
}

# Check the kernel parameter
kernel_parameter_chk

# Check results and output
if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
    read -p "Do you want to apply remediation? (y/n): " user_choice

    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        # Remediation
        echo "Setting kernel.yama.ptrace_scope to 1..."
        echo "kernel.yama.ptrace_scope = $l_kpvalue" >> /etc/sysctl.d/60-kernel_sysctl.conf
        sysctl -w "$l_kpname=$l_kpvalue"
        echo "Remediation applied. Please verify the changes."
    else
        echo "No remediation applied."
    fi
fi
