#!/bin/bash

# Configuration directory for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-user_emulation.rules"

# Desired audit rules for 64-bit systems
desired_rules=(
    "-a always,exit -F arch=b64 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
    "-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation"
)

# Check for existing rules in the specified rules file
echo "Checking existing audit rules in $audit_rules_file..."
if [[ -f "$audit_rules_file" ]]; then
    existing_rules=$(grep -E '^ *-a *always,exit' "$audit_rules_file")
else
    existing_rules=""
fi

# Function to check if a rule exists
rule_exists() {
    local rule="$1"
    [[ $existing_rules == *"$rule"* ]]
}

# Check and add missing rules
for rule in "${desired_rules[@]}"; do
    if ! rule_exists "$rule"; then
        echo "Rule not found: $rule"
        read -p "Do you want to add this rule? (y/n): " user_choice
        if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
            echo "$rule" >> "$audit_rules_file"
            echo "Added rule: $rule"
        else
            echo "Rule not added: $rule"
        fi
    else
        echo "Rule already exists: $rule"
    fi
done

# Load the new rules
echo "Loading new audit rules..."
augenrules --load

# Check if a reboot is required
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "Reboot required to load rules."
else
    echo "Audit rules loaded successfully."
fi
