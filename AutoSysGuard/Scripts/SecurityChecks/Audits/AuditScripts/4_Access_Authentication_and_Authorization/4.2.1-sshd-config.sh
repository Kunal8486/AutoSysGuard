#!/usr/bin/env bash

audit_sshd_config() {
  echo "Performing audit for /etc/ssh/sshd_config permissions and ownership..."
  l_output="" l_output2=""

  l_file="/etc/ssh/sshd_config"
  l_mask='0177'  # 0600 is the most permissive
  l_maxperm="$( printf '%o' $(( 0777 & ~$l_mask)) )"

  # Check file existence
  if [ ! -e "$l_file" ]; then
    echo "File $l_file does not exist. Audit cannot proceed."
    exit 1
  fi

  # Audit file permissions, ownership, and group ownership
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

    if [ "$l_fgroup" != "root" ]; then
      l_output2="$l_output2\n - \"$l_file\" is owned by group \"$l_fgroup\" (should be owned by group \"root\")"
    else
      l_output="$l_output\n - \"$l_file\" is correctly owned by group: \"$l_fgroup\""
    fi
  done < <(stat -Lc '%#a %U %G' "$l_file")

  # Display audit result
  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **$l_output\n"
  else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:$l_output2\n"
    remediate_sshd_config
  fi
}

remediate_sshd_config() {
  read -p "Would you like to apply remediation? (y/n): " apply_remediation
  if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
    echo "Applying remediation..."

    l_file="/etc/ssh/sshd_config"

    # Correct file permissions
    echo " - Setting correct permissions (0600) on $l_file"
    chmod u-x,og-rwx "$l_file"

    # Correct ownership and group ownership
    echo " - Setting ownership to root:root on $l_file"
    chown root:root "$l_file"

    echo "Remediation applied successfully."
  else
    echo "Remediation skipped."
  fi
}

# Run the audit
audit_sshd_config
