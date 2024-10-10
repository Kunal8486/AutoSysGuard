#!/bin/bash

# Configuration directory for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-time-change.rules"

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
    "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change"
    "-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k time-change"
    "-w /etc/localtime -p wa -k time-change"
)

# Define the rule for 32-bit systems
rule_32_bit="-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime,stime -k time-change"

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

# For 32-bit systems, also check the additional rule
if [[ $(uname -m) == "i686" ]] && ! rules_exist "$rule_32_bit"; then
    add_rule "$rule_32_bit"
elif [[ $(uname -m) == "i686" ]]; then
    echo "Rule already exists: $rule_32_bit"
fi

# Load the new rules
echo "Loading new audit rules..."
augenrules --load

# Check if a reboot is required
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "Reboot required to load rules."
else
    echo "Audit rules loaded successfully."
fi
