#!/bin/bash

# Define the audit rules file
AUDIT_RULES_FILE="/etc/audit/rules.d/50-session.rules"

# Create or edit the audit rules file with necessary rules
{
    echo "# Audit rules for monitoring session initiation information"
    echo "-w /var/run/utmp -p wa -k session"
    echo "-w /var/log/wtmp -p wa -k session"
    echo "-w /var/log/btmp -p wa -k session"
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
&&(/\/var\/run\/utmp/ \
||/\/var\/log\/wtmp/ \
||/\/var\/log\/btmp/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules

# Check running configuration
echo "Checking running configuration of audit rules..."
auditctl -l | awk '/^ *-w/ \
&&(/\/var\/run\/utmp/ \
||/\/var\/log\/wtmp/ \
||/\/var\/log\/btmp/) \
&&/ +-p *wa/ \
&&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)'
