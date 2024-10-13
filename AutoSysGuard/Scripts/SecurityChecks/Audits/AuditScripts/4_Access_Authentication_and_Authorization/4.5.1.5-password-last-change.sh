#!/usr/bin/env bash

audit_password_change() {
  # Audit for users with future last password change date
  echo "Performing audit for last password change of all users..."
  l_output2=""

  while read -r l_user; do
    # Get the last password change date
    l_change="$(chage --list "$l_user" | awk -F: '($1 ~ /^\s*Last\s+password\s+change/ && $2 !~ /never/){print $2}' | xargs)"
    if [[ "$(date -d "$l_change" +%s)" -gt "$(date +%s)" ]]; then
      l_output2="$l_output2\n - User: \"$l_user\" last password change is in the future \"$l_change\""
    fi
  done < <(awk -F: '($2 ~ /^[^*!xX\n\r][^\n\r]+/){print $1}' /etc/shadow)

  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - All user password changes are in the past \n"
  else
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :$l_output2\n"
    echo "Do you want to apply remediation? (y/n)"
    read -r user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
      apply_remediation "$l_output2"
    else
      echo "Remediation not applied."
    fi
  fi
}

apply_remediation() {
  # Apply remediation by locking or expiring accounts with future password change dates
  echo "Applying remediation..."
  while IFS= read -r line; do
    l_user=$(echo "$line" | grep -oP '(?<=User: ")[^"]+')
    echo "Locking or expiring password for user \"$l_user\""
    passwd -l "$l_user"  # Lock the user account
    chage -E 0 "$l_user"  # Expire the password
    echo "Account for \"$l_user\" locked and password expired."
  done <<< "$1"
  echo "Remediation applied successfully."
}

# Run the audit
audit_password_change
