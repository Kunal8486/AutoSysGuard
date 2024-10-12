#!/bin/bash

# Set recommended backlog limit
recommended_limit=8192
grub_config_file="/etc/default/grub"

# Check if audit_backlog_limit is set in grub configuration
audit_backlog_limit=$(grep -Po 'GRUB_CMDLINE_LINUX="[^"]*' "$grub_config_file" | grep -o 'audit_backlog_limit=[0-9]*')

if [ -n "$audit_backlog_limit" ]; then
    current_limit=$(echo "$audit_backlog_limit" | cut -d '=' -f2)
    echo "Current audit_backlog_limit is set to: $current_limit"
    
    if (( current_limit >= recommended_limit )); then
        echo "Audit backlog limit is sufficient."
    else
        echo "Current audit backlog limit is insufficient."
        read -p "Do you want to set it to the recommended value of $recommended_limit? (y/n): " set_limit_choice
        if [[ "$set_limit_choice" == "y" || "$set_limit_choice" == "Y" ]]; then
            # Update audit_backlog_limit in GRUB_CMDLINE_LINUX
            sed -i "s/^\(GRUB_CMDLINE_LINUX=\".*\)\"/\1 audit_backlog_limit=$recommended_limit\"/" "$grub_config_file"
            echo "audit_backlog_limit has been updated to $recommended_limit in GRUB_CMDLINE_LINUX."
            # Update grub configuration
            update-grub
            echo "Grub configuration has been updated."
        else
            echo "Audit backlog limit will not be changed."
        fi
    fi
else
    echo "audit_backlog_limit is not set. Setting it to the recommended value of $recommended_limit."
    read -p "Do you want to proceed? (y/n): " proceed_choice
    if [[ "$proceed_choice" == "y" || "$proceed_choice" == "Y" ]]; then
        # Add audit_backlog_limit to GRUB_CMDLINE_LINUX
        sed -i "s/^\(GRUB_CMDLINE_LINUX=\".*\)\"/\1 audit_backlog_limit=$recommended_limit\"/" "$grub_config_file"
        echo "audit_backlog_limit has been added to GRUB_CMDLINE_LINUX."
        # Update grub configuration
        update-grub
        echo "Grub configuration has been updated."
    else
        echo "Audit backlog limit will not be set."
    fi
fi

# Audit check for grub.cfg files
echo "Checking for existing grub.cfg files..."
grub_cfg_files=$(find -L /boot -type f -name 'grub.cfg')

if [ -z "$grub_cfg_files" ]; then
    echo "No grub.cfg files found in /boot."
else
    echo "Checking grub.cfg files for audit_backlog_limit setting..."
    backlog_check_result=$(grep -Ph -- '^\h*linux\b' $grub_cfg_files | grep -Pv 'audit_backlog_limit=[0-9]+\b')

    if [ -z "$backlog_check_result" ]; then
        echo "Audit backlog limit is confirmed set in grub.cfg files."
    else
        echo "There are grub.cfg files without the audit_backlog_limit setting."
        echo "Please ensure that 'audit_backlog_limit=N' is included in the kernel parameters."
    fi
fi
