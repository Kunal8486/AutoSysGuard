#!/bin/bash

# Configuration directory for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-system_locale.rules"

# Function to check if rules exist
rules_exist() {
    local rule="$1"
    grep -q -E "$rule" "$audit_rules_file"
}

# Function to add rules
add_rule() {
    local rule="$1"
    echo "$rule" >> "$audit_rules_file"
    echo "Added rule: $rule"
}

# Define the rules for 64-bit systems
rules_64_bit=(
    "-a always,exit -F arch=b64 -S sethostname,setdomainname -k system-locale"
    "-a always,exit -F arch=b32 -S sethostname,setdomainname -k system-locale"
    "-w /etc/issue -p wa -k system-locale"
    "-w /etc/issue.net -p wa -k system-locale"
    "-w /etc/hosts -p wa -k system-locale"
    "-w /etc/networks -p wa -k system-locale"
    "-w /etc/network/ -p wa -k system-locale"
)

# Checking if the rules file exists
if [[ ! -f "$audit_rules_file" ]]; then
    touch "$audit_rules_file"
fi

echo "Checking existing audit rules in $audit_rules_file..."

# Check for each rule and add it if missing
for rule in "${rules_64_bit[@]}"; do
    if ! rules_exist "$rule"; then
        add_rule "$rule"
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
