#!/bin/bash

# Configuration for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-privileged.rules"

# Get the minimum UID from /etc/login.defs
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)

# Function to check if a privileged command rule exists
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
if [[ ! -f "$audit_rules_file" ]]; then
    touch "$audit_rules_file"
fi

# Collect privileged commands (setuid/setgid) from all relevant partitions
echo "Collecting privileged commands..."

NEW_DATA=()
for PARTITION in $(findmnt -n -l -k -it $(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd,) | grep -Pv "noexec|nosuid" | awk '{print $1}'); do
    while IFS= read -r PRIVILEGED; do
        NEW_DATA+=("-a always,exit -F path=$PRIVILEGED -F perm=x -F auid>=$UID_MIN -F auid!=unset -k privileged")
    done < <(find "${PARTITION}" -xdev -perm /6000 -type f)
done

echo "Checking existing rules..."
# Check for each new rule and add it if missing
for rule in "${NEW_DATA[@]}"; do
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
