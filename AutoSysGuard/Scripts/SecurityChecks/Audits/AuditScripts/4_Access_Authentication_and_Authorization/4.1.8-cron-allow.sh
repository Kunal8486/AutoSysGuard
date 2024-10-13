#!/usr/bin/env bash

# Audit function
audit_cron_files() {
    local l_output="" l_output2=""

    # Check if cron is installed
    if dpkg-query -W cron > /dev/null 2>&1; then
        local l_file="/etc/cron.allow"
        [ -e /etc/cron.deny ] && l_output2="$l_output2\n - cron.deny exists"
        
        # Check if cron.allow exists
        if [ ! -e /etc/cron.allow ]; then
            l_output2="$l_output2\n - cron.allow doesn't exist"
        else
            local l_mask='0137'
            local l_maxperm="$( printf '%o' $(( 0777 & ~$l_mask)) )"
            
            # Audit permissions, ownership, and group
            while read l_mode l_fown l_fgroup; do
                if [ $(( l_mode & l_mask )) -gt 0 ]; then
                    l_output2="$l_output2\n - \"$l_file\" is mode: \"$l_mode\" (should be mode: \"$l_maxperm\" or more restrictive)"
                else
                    l_output="$l_output\n - \"$l_file\" is correctly set to mode: \"$l_mode\""
                fi
                if [ "$l_fown" != "root" ]; then
                    l_output2="$l_output2\n - \"$l_file\" is owned by user \"$l_fown\" (should be owned by \"root\")"
                else
                    l_output="$l_output\n - \"$l_file\" is correctly owned by user: \"$l_fown\""
                fi
                if [ "$l_fgroup" != "crontab" ]; then
                    l_output2="$l_output2\n - \"$l_file\" is owned by group: \"$l_fgroup\" (should be owned by group: \"crontab\")"
                else
                    l_output="$l_output\n - \"$l_file\" is correctly owned by group: \"$l_fgroup\""
                fi
            done < <(stat -Lc '%#a %U %G' "$l_file")
        fi
    else
        l_output="$l_output\n - cron is not installed on the system"
    fi

    # Display audit results
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **$l_output\n"
        return 0
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:$l_output2\n"
        return 1
    fi
}

# Remediation function
remediate_cron_files() {
    if dpkg-query -W cron > /dev/null 2>&1; then
        local l_file="/etc/cron.allow"
        local l_mask='0137'
        local l_maxperm="$( printf '%o' $(( 0777 & ~$l_mask)) )"
        
        # Remove cron.deny if it exists
        if [ -e /etc/cron.deny ]; then
            echo -e " - Removing \"/etc/cron.deny\""
            rm -f /etc/cron.deny
        fi
        
        # Create cron.allow if it doesn't exist
        if [ ! -e /etc/cron.allow ]; then
            echo -e " - Creating \"$l_file\""
            touch "$l_file"
        fi

        # Set correct permissions, ownership, and group
        while read l_mode l_fown l_fgroup; do
            if [ $(( l_mode & l_mask )) -gt 0 ]; then
                echo -e " - Removing excessive permissions from \"$l_file\""
                chmod u-x,g-wx,o-rwx "$l_file"
            fi
            if [ "$l_fown" != "root" ]; then
                echo -e " - Changing owner on \"$l_file\" from: \"$l_fown\" to: \"root\""
                chown root "$l_file"
            fi
            if [ "$l_fgroup" != "crontab" ]; then
                echo -e " - Changing group owner on \"$l_file\" from: \"$l_fgroup\" to: \"crontab\""
                chgrp crontab "$l_file"
            fi
        done < <(stat -Lc '%#a %U %G' "$l_file")
    else
        echo -e "- cron is not installed on the system, no remediation required\n"
    fi
}

# Run the audit
audit_cron_files
if [[ $? -ne 0 ]]; then
    # If audit fails, ask the user if they want to apply remediation
    read -p "Do you want to apply remediation? (y/n): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        remediate_cron_files
    else
        echo "Remediation skipped."
    fi
fi
