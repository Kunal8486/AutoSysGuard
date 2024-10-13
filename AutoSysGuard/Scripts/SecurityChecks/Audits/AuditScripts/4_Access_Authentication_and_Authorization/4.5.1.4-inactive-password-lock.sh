#!/usr/bin/env bash

# Function to audit the INACTIVE period for user accounts
audit_inactive_period() {
  echo "Performing audit for INACTIVE period (no more than 30 days)..."
  local inactive_default
  local l_output2=""
  
  # Check default INACTIVE period
  inactive_default=$(useradd -D | grep INACTIVE | cut -d= -f2)
  echo "Default INACTIVE period is set to: $inactive_default days"
  
  if [ "$inactive_default" -gt 30 ] || [ "$inactive_default" -lt 0 ]; then
    echo -e "\n- Audit Result:\n ** FAIL **\n - Default INACTIVE period is greater than 30 days."
  else
    echo -e "\n- Default INACTIVE period conforms to site policy."
  fi

  # Check if any users have an INACTIVE period greater than 30 days or set to -1 (disabled)
  while read -r l_user l_inactive; do
    # Skip users who already have INACTIVE set to 30 or less
    if [ "$l_inactive" -le 30 ] && [ "$l_inactive" -ge 0 ]; then
      continue
    fi
    l_output2="$l_output2\n - User: \"$l_user\" has INACTIVE period set to \"$l_inactive\" days."
  done < <(awk -F: '(/^[^:]+:[^!*]/ && ($7~/(\s*|-1)/ || $7>30)){print $1 " " $7}' /etc/shadow)

  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - All user INACTIVE periods are within the site policy.\n"
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

# Function to apply remediation for users with incorrect INACTIVE periods
apply_remediation() {
  echo "Applying remediation..."
  
  # Set the default INACTIVE period to 30 days
  echo "Setting default INACTIVE period to 30 days..."
  useradd -D -f 30
  
  # Modify INACTIVE period for each user returned by the audit
  while IFS= read -r line; do
    l_user=$(echo "$line" | awk -F'"' '{print $2}')
    echo "Setting INACTIVE period to 30 days for user \"$l_user\"..."
    chage --inactive 30 "$l_user"
    echo "INACTIVE period set for \"$l_user\"."
  done <<< "$1"

  echo "Remediation applied successfully."
}

# Run the audit
audit_inactive_period
