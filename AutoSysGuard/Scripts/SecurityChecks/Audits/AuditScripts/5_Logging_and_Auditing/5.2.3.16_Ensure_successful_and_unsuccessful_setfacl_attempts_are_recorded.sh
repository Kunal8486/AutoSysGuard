#!/bin/bash

# Define the audit rules file
AUDIT_RULES_FILE="/etc/audit/rules.d/50-perm_chng.rules"

# Create or edit the audit rules file with necessary rules
{
    echo "# Audit rules for monitoring setfacl command usage"
    echo "-a always,exit -F path=/usr/bin/setfacl -F perm=x -F auid>=1000 -F auid!=unset -k perm_chng"
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
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
if [ -n "${UID_MIN}" ]; then
    awk "/^ *-a *always,exit/ \
    && / -F *path=\/usr\/bin\/setfacl/ \
    && / -F *perm=x/ \
    && / -F *auid>=${UID_MIN}/ \
    && / -F *auid!=unset/ \
    && (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)" /etc/audit/rules.d/*.rules
else
    printf "ERROR: Variable 'UID_MIN' is unset.\n"
fi

# Check running configuration
echo "Checking running configuration of audit rules..."
auditctl -l | awk "/^ *-a *always,exit/ \
&& / -F *path=\/usr\/bin\/setfacl/ \
&& / -F *perm=x/ \
&& / -F *auid>=1000/ \
&& / -F *auid!=-1/ \
&& (/ key= *[!-~]* *$/ || / -k *[!-~]* *$/)"
