#!/bin/bash

# Define the audit rules file
AUDIT_RULES_FILE="/etc/audit/rules.d/50-login.rules"

# Create or edit the audit rules file with necessary rules
{
    echo "# Audit rules for monitoring login and logout events"
    echo "-w /var/log/lastlog -p wa -k logins"
    echo "-w /var/run/faillock -p wa -k logins"
} > "$AUDIT_RULES_FILE"

# Load the audit rules into active configuration
augenrules --load

# Check if a reboot is required to apply the changes
if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
    echo "Reboot required to load rules."
else
    echo "Audit rules loaded successfully."
fi

# Check on-disk rules
echo "Checking on-disk audit rules..."
awk '/^ *-w/ \
&&(/\/var\/log\/lastlog/ \
||/\/var\/run\/faillock/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules

# Check running configuration
echo "Checking running configuration of audit rules..."
auditctl -l | awk '/^ *-w/ \
&&(/\/var\/log\/lastlog/ \
||/\/var\/run\/faillock/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)'
