#!/bin/bash

# Check if audit=1 is set in grub configuration
grub_config_file="/etc/default/grub"
audit_setting=$(grep -Po 'GRUB_CMDLINE_LINUX="[^"]*' "$grub_config_file" | grep -o 'audit=1')

if [ -n "$audit_setting" ]; then
    echo "Auditing for processes that start prior to auditd is already enabled."
else
    echo "Auditing for processes that start prior to auditd is not enabled."
    read -p "Do you want to enable it? (y/n): " enable_choice
    if [[ "$enable_choice" == "y" || "$enable_choice" == "Y" ]]; then
        # Add audit=1 to GRUB_CMDLINE_LINUX
        sed -i 's/^\(GRUB_CMDLINE_LINUX=".*\)"/\1 audit=1"/' "$grub_config_file"
        echo "audit=1 has been added to GRUB_CMDLINE_LINUX."

        # Update grub configuration
        update-grub
        echo "Grub configuration has been updated."
    else
        echo "Auditing for processes that start prior to auditd will not be enabled."
    fi
fi

# Audit check for grub.cfg files
echo "Checking for existing grub.cfg files..."
grub_cfg_files=$(find -L /boot -type f -name 'grub.cfg')

if [ -z "$grub_cfg_files" ]; then
    echo "No grub.cfg files found in /boot."
else
    echo "Checking grub.cfg files for audit=1..."
    audit_check_result=$(grep -Ph -- '^\h*linux\b' $grub_cfg_files | grep -v 'audit=1')

    if [ -z "$audit_check_result" ]; then
        echo "Audit for processes that start prior to auditd is confirmed enabled in grub.cfg files."
    else
        echo "There are grub.cfg files without the audit=1 setting."
        echo "Please ensure that 'audit=1' is included in the kernel parameters."
    fi
fi
