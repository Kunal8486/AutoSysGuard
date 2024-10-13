#!/usr/bin/env bash

# Function to check the core file limit
check_core_file_limit() {
    core_limit=$(grep -Es '^(\*|\s).*hard.*core.*(\s+#.*)?$' /etc/security/limits.conf)
    if [[ "$core_limit" == "* hard core 0" ]]; then
        echo "Audit Result:\n ** PASS **\n - Core file limit is correctly set to 0."
    else
        echo "Audit Result:\n ** FAIL **\n - Core file limit is not set to 0."
        return 1
    fi
}

# Function to check the fs.suid_dumpable parameter
check_suid_dumpable() {
    local l_kpname="fs.suid_dumpable"
    local l_kpvalue="0"
    
    # Check running configuration
    local l_krp=$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)
    
    if [[ "$l_krp" == "$l_kpvalue" ]]; then
        echo " - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration."
    else
        echo " - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
        return 1
    fi
    
    # Check if the parameter is set in configuration files
    local config_files=$(grep -rl "^$l_kpname" /etc/sysctl.d/*.conf /etc/sysctl.conf)
    
    if [[ -n "$config_files" ]]; then
        while read -r file; do
            local fkpvalue=$(grep "^$l_kpname" "$file" | awk -F= '{print $2}' | xargs)
            if [[ "$fkpvalue" == "$l_kpvalue" ]]; then
                echo " - \"$l_kpname\" is correctly set to \"$fkpvalue\" in \"$file\"."
            else
                echo " - \"$l_kpname\" is incorrectly set to \"$fkpvalue\" in \"$file\" and should have a value of: \"$l_kpvalue\"."
                return 1
            fi
        done <<< "$config_files"
    else
        echo " - \"$l_kpname\" is not set in any configuration file."
        return 1
    fi
}

# Function to check if systemd-coredump is installed
check_coredump_installed() {
    local status=$(systemctl is-enabled coredump.service 2>/dev/null)
    if [[ "$status" =~ (enabled|masked|disabled) ]]; then
        echo "systemd-coredump is installed (status: $status)."
        return 0
    else
        echo "systemd-coredump is not installed."
        return 1
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    
    # Update /etc/security/limits.conf
    if ! grep -q '^* hard core 0' /etc/security/limits.conf; then
        echo "* hard core 0" >> /etc/security/limits.conf
        echo "Added '* hard core 0' to /etc/security/limits.conf."
    fi

    # Update fs.suid_dumpable in sysctl.conf
    if ! grep -q '^fs.suid_dumpable' /etc/sysctl.d/*.conf; then
        printf "fs.suid_dumpable = 0\n" >> /etc/sysctl.d/60-fs_sysctl.conf
        echo "Added 'fs.suid_dumpable = 0' to /etc/sysctl.d/60-fs_sysctl.conf."
    fi

    # Set the active kernel parameter
    sysctl -w fs.suid_dumpable=0
    echo "Set active kernel parameter fs.suid_dumpable=0."

    # Check if systemd-coredump is installed and apply its remediation
    if check_coredump_installed; then
        if [ -f /etc/systemd/coredump.conf ]; then
            sed -i 's/^Storage=.*/Storage=none/' /etc/systemd/coredump.conf
            sed -i 's/^ProcessSizeMax=.*/ProcessSizeMax=0/' /etc/systemd/coredump.conf
            echo "Updated /etc/systemd/coredump.conf to disable coredump storage and set ProcessSizeMax to 0."
            systemctl daemon-reload
            echo "Systemd daemon reloaded."
        fi
    fi
}

# Perform audits
check_core_file_limit
core_file_check_status=$?

check_suid_dumpable
suid_dumpable_check_status=$?

check_coredump_installed
coredump_check_status=$?

# Check if any audit failed and prompt for remediation
if [[ $core_file_check_status -ne 0 || $suid_dumpable_check_status -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
else
    echo "All configurations are compliant."
fi
