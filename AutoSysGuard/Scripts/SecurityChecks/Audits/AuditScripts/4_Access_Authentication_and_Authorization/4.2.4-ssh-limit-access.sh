#!/usr/bin/env bash

# Function to check the audit
check_audit() {
    local user=$(whoami)
    local hostname=$(hostname)
    local ip_address=$(grep "$hostname" /etc/hosts | awk '{print $1}')
    
    # Check sshd config for allow/deny users/groups
    local command1_output
    command1_output=$(sshd -T -C user="$user" -C host="$hostname" -C addr="$ip_address" | grep -Pi '^\s*(allow|deny)(users|groups)\s+\H+(\s+.*)?$')
    
    local command2_output
    command2_output=$(grep -Pis '^\s*(allow|deny)(users|groups)\s+\H+(\s+.*)?$' /etc/ssh/sshd_config)
    
    echo "Audit Results:"
    echo "---------------------"
    echo "Command 1 Output:"
    echo "$command1_output"
    echo "Command 2 Output:"
    echo "$command2_output"
    echo "---------------------"

    # Check if either command output matches the required patterns
    if [[ -z "$command1_output" && -z "$command2_output" ]]; then
        echo "Audit Result: ** FAIL **"
        return 1
    else
        echo "Audit Result: *** PASS ***"
        return 0
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Editing /etc/ssh/sshd_config to set AllowUsers or AllowGroups or DenyUsers or DenyGroups."
    
    # Sample user input for remediation
    read -p "Enter the users you want to allow (AllowUsers) or deny (DenyUsers): " userlist
    read -p "Enter the groups you want to allow (AllowGroups) or deny (DenyGroups): " grouplist

    # Backing up the original configuration file
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

    # Setting the configuration
    {
        echo "AllowUsers $userlist"
        echo "AllowGroups $grouplist"
        echo "DenyUsers $userlist"
        echo "DenyGroups $grouplist"
    } >> /etc/ssh/sshd_config
    
    echo "Remediation applied. Please review /etc/ssh/sshd_config."
    systemctl restart sshd
}

# Main script execution
check_audit
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply the remediation? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "Remediation not applied."
    fi
else
    echo "No remediation needed."
fi
