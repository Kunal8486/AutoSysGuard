#!/bin/bash

# Configuration for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-identity.rules"

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

# Collect audit rules for events that modify user/group information
echo "Collecting audit rules for user/group modification events..."

# Define audit rules to watch user/group modification files
rules=(
    "-w /etc/group -p wa -k identity"
    "-w /etc/passwd -p wa -k identity"
    "-w /etc/gshadow -p wa -k identity"
    "-w /etc/shadow -p wa -k identity"
    "-w /etc/security/opasswd -p wa -k identity"
)

# Add rules
for rule in "${rules[@]}"; do
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
