#!/usr/bin/env bash

audit_at() {
  echo "Performing audit for /etc/at.allow and /etc/at.deny..."
  l_output="" l_output2=""

  if dpkg-query -W at > /dev/null 2>&1; then
    l_file="/etc/at.allow"
    
    # Check if /etc/at.deny exists
    [ -e /etc/at.deny ] && l_output2="$l_output2\n - at.deny exists"
    
    # Check if /etc/at.allow exists
    if [ ! -e /etc/at.allow ]; then
      l_output2="$l_output2\n - at.allow doesn't exist"
    else
      l_mask='0137'
      l_maxperm="$( printf '%o' $(( 0777 & ~$l_mask)) )"
      
      # Get file attributes and check permissions
      while read l_mode l_fown l_fgroup; do
        if [ $(( l_mode & l_mask )) -gt 0 ]; then
          l_output2="$l_output2\n - \"$l_file\" is mode: \"$l_mode\" (should be mode: \"$l_maxperm\" or more restrictive)"
        else
          l_output="$l_output\n - \"$l_file\" is correctly set to mode: \"$l_mode\""
        fi

        # Check ownership
        if [ "$l_fown" != "root" ]; then
          l_output2="$l_output2\n - \"$l_file\" is owned by user \"$l_fown\" (should be owned by \"root\")"
        else
          l_output="$l_output\n - \"$l_file\" is correctly owned by user: \"$l_fown\""
        fi
        
        # Check group ownership
        if [ "$l_fgroup" != "root" ]; then
          l_output2="$l_output2\n - \"$l_file\" is owned by group: \"$l_fgroup\" (should be owned by group: \"root\")"
        else
          l_output="$l_output\n - \"$l_file\" is correctly owned by group: \"$l_fgroup\""
        fi
      done < <(stat -Lc '%#a %U %G' "$l_file")
    fi
  else
    l_output="$l_output\n - at is not installed on the system"
  fi

  # Show audit result
  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **$l_output\n"
  else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:$l_output2\n"
    remediate_at
  fi
}

remediate_at() {
  read -p "Would you like to apply remediation? (y/n): " apply_remediation
  if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
    echo "Applying remediation..."

    if dpkg-query -W at > /dev/null 2>&1; then
      l_file="/etc/at.allow"
      l_mask='0137'
      l_maxperm="$( printf '%o' $(( 0777 & ~$l_mask)) )"
      
      # Remove /etc/at.deny if it exists
      if [ -e /etc/at.deny ]; then
        echo -e " - Removing \"/etc/at.deny\""
        rm -f /etc/at.deny
      fi
      
      # Create /etc/at.allow if it doesn't exist
      if [ ! -e /etc/at.allow ]; then
        echo -e " - Creating \"$l_file\""
        touch "$l_file"
      fi
      
      # Fix permissions, ownership, and group ownership
      while read l_mode l_fown l_fgroup; do
        if [ $(( l_mode & l_mask )) -gt 0 ]; then
          echo -e " - Removing excessive permissions from \"$l_file\""
          chmod u-x,g-wx,o-rwx "$l_file"
        fi
        if [ "$l_fown" != "root" ]; then
          echo -e " - Changing owner on \"$l_file\" from \"$l_fown\" to \"root\""
          chown root "$l_file"
        fi
        if [ "$l_fgroup" != "root" ]; then
          echo -e " - Changing group owner on \"$l_file\" from \"$l_fgroup\" to \"root\""
          chgrp root "$l_file"
        fi
      done < <(stat -Lc '%#a %U %G' "$l_file")
    else
      echo -e "- at is not installed on the system, no remediation required\n"
    fi
  else
    echo "Remediation skipped."
  fi
}

audit_at
