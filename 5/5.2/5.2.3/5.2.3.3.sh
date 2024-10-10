#!/bin/bash

# Configuration directory for audit rules
audit_rules_dir="/etc/audit/rules.d"
audit_rules_file="$audit_rules_dir/50-sudo.rules"

# Function to retrieve the sudo log file path
get_sudo_log_file() {
    grep -r logfile /etc/sudoers* | sed -e 's/.*logfile=//;s/,? .*//' -e 's/"//g'
}

# Get the sudo log file path
SUDO_LOG_FILE=$(get_sudo_log_file)

# Check if the sudo log file variable is set
if [ -z "$SUDO_LOG_FILE" ]; then
    echo "ERROR: Variable 'SUDO_LOG_FILE' is unset."
    exit 1
fi

# Check for existing rules in the specified rules file
echo "Checking existing audit rules in $audit_rules_file..."
if [[ -f "$audit_rules_file" ]]; then
    existing_rules=$(grep -E '^ *-w' "$audit_rules_file")
else
    existing_rules=""
fi

# Function to check if a rule exists
rule_exists() {
    local rule="$1"
    [[ $existing_rules == *"$rule"* ]]
}

# Desired audit rule
desired_rule="-w $SUDO_LOG_FILE -p wa -k sudo_log_file"

# Check and add the missing rule
if ! rule_exists "$desired_rule"; then
    echo "Rule not found: $desired_rule"
    read -p "Do you want to add this rule? (y/n): " user_choice
    if [[ "$user_choice" == "y" || "$user_choice" == "Y" ]]; then
        echo "$desired_rule" >> "$audit_rules_file"
        echo "Added rule: $desired_rule"
    else
        echo "Rule not added: $desired_rule"
    fi
else
    echo "Rule already exists: $desired_rule"
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
