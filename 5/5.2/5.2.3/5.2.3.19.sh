#!/bin/bash

# Define the audit rules file
AUDIT_RULES_FILE="/etc/audit/rules.d/50-kernel_modules.rules"

# Create or edit the audit rules file with necessary rules
{
    echo "# Audit rules for monitoring kernel module loading and unloading"
    echo "-a always,exit -F arch=b64 -S init_module,finit_module,delete_module,create_module,query_module -F auid>=1000 -F auid!=unset -k kernel_modules"
    echo "-a always,exit -F path=/usr/bin/kmod -F perm=x -F auid>=1000 -F auid!=unset -k kernel_modules"
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
awk '/^ *-a *always,exit/ \
&&/ -F *arch=b[2346]{2}/ \
&&(/ -F auid!=unset/||/ -F auid!=-1/||/ -F auid!=4294967295/) \
&&/ -S/ \
&&(/init_module/ \
||/finit_module/ \
||/delete_module/ \
||/create_module/ \
||/query_module/) \
&&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules

# Check running configuration
echo "Checking running configuration of audit rules..."
auditctl -l | awk '/^ *-a *always,exit/ \
&&/ -F *arch=b[2346]{2}/ \
&&(/ -F auid!=unset/||/ -F auid!=-1/||/ -F auid!=4294967295/) \
&&/ -S/ \
&&(/init_module/ \
||/finit_module/ \
||/delete_module/ \
||/create_module/ \
||/query_module/) \
&&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)'

# Check symlink integrity for kmod
echo "Checking symlink integrity for kmod..."
S_LINKS=$(ls -l /usr/sbin/lsmod /usr/sbin/rmmod /usr/sbin/insmod /usr/sbin/modinfo /usr/sbin/modprobe /usr/sbin/depmod | grep -v " -> ../bin/kmod" || true)
if [[ "$S_LINKS" != "" ]]; then
    printf "Issue with symlinks: ${S_LINKS}\n"
else
    printf "OK\n"
fi
