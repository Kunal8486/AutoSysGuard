#!/bin/bash

# Configuration for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-perm_mod.rules"

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

# Collect UID_MIN from login.defs
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

# Check if UID_MIN is set
if [[ -z "${UID_MIN}" ]]; then
    echo "ERROR: Variable 'UID_MIN' is unset."
    exit 1
fi

# Collect audit rules for DAC permission modification events
echo "Collecting audit rules for DAC permission modification events..."

# Define audit rules for file permission changes
rules=(
    "-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod"
    "-a always,exit -F arch=b64 -S chown,fchown,lchown,fchownat -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod"
    "-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod"
    "-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod"
    "-a always,exit -F arch=b64 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod"
    "-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod"
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
