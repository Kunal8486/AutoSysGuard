#!/bin/bash

# Configuration for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-access.rules"

# Get the minimum UID from /etc/login.defs
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

# Function to check if a file exists and is writable
check_file() {
    [[ -f "$1" ]] || touch "$1"
}

# Function to check if a specific rule exists in the audit rules file
rules_exist() {
    local rule="$1"
    grep -q -E "$rule" "$audit_rules_file"
}

# Function to add rules to the rules file
add_rule() {
    local rule="$1"
    echo "$rule" >> "$audit_rules_file"
    echo "Added rule: $rule"
}

# Create or verify the rules file exists
check_file "$audit_rules_file"

# Collect audit rules for unsuccessful file access attempts
echo "Collecting audit rules for unsuccessful file access attempts..."

# Ensure UID_MIN is set
if [[ -z "$UID_MIN" ]]; then
    echo "ERROR: Variable 'UID_MIN' is unset."
    exit 1
fi

# Define audit rules for both 64-bit and 32-bit architectures
rules_b64=(
    "-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access"
    "-a always,exit -F arch=b64 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM -F auid>=$UID_MIN -F auid!=unset -k access"
)

rules_b32=(
    "-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EACCES -F auid>=$UID_MIN -F auid!=unset -k access"
    "-a always,exit -F arch=b32 -S creat,open,openat,truncate,ftruncate -F exit=-EPERM -F auid>=$UID_MIN -F auid!=unset -k access"
)

# Add 64-bit rules
for rule in "${rules_b64[@]}"; do
    if ! rules_exist "$rule"; then
        add_rule "$rule"
    else
        echo "Rule already exists: $rule"
    fi
done

# Add 32-bit rules
for rule in "${rules_b32[@]}"; do
    if ! rules_exist "$rule"; then
        add_rule "$rule"
    else
        echo "Rule already exists: $rule"
    fi
done

# Load the new rules into the active configuration
echo "Loading new audit rules..."
augenrules --load

# Check if a reboot is required
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "Reboot required to load rules."
else
    echo "Audit rules loaded successfully."
fi
