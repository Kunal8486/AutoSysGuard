#!/usr/bin/env bash

# Function to check the PASS_MAX_DAYS in /etc/login.defs
audit_pass_max_days() {
  echo "Performing audit for PASS_MAX_DAYS (not exceeding 365 days)..."
  
  # Check PASS_MAX_DAYS value in /etc/login.defs
  pass_max_days=$(grep -E "^PASS_MAX_DAYS\s+[0-9]+" /etc/login.defs | awk '{print $2}')
  pass_min_days=$(grep -E "^PASS_MIN_DAYS\s+[0-9]+" /etc/login.defs | awk '{print $2}')

  if [[ -z "$pass_max_days" || "$pass_max_days" -gt 365 || "$pass_max_days" -le "$pass_min_days" ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **\n - PASS_MAX_DAYS exceeds 365 days or is not greater than PASS_MIN_DAYS."
    return 1
  else
    echo -e "\n- Audit Result:\n ** PASS **\n - PASS_MAX_DAYS is correctly set to $pass_max_days days."
  fi
}

# Function to check PASS_MAX_DAYS for individual users
audit_user_pass_max_days() {
  failed_users=()
  while IFS=: read -r user pass uid gid gecos home shell; do
    if [[ "$pass" != "*" && "$pass" != "!" && "$pass" != "" ]]; then
      user_max_days=$(chage --list "$user" | awk -F: '/^Maximum/ {print $2}' | xargs)
      user_min_days=$(chage --list "$user" | awk -F: '/^Minimum/ {print $2}' | xargs)

      if [[ -n "$user_max_days" && ( "$user_max_days" -gt 365 || "$user_max_days" -le "$user_min_days" ) ]]; then
        failed_users+=("$user")
      fi
    fi
  done < /etc/shadow

  if [[ ${#failed_users[@]} -gt 0 ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo "- The following users have PASS_MAX_DAYS exceeding 365 days or not greater than PASS_MIN_DAYS:"
    for user in "${failed_users[@]}"; do
      echo "  - User: $user"
    done
    return 1
  else
    echo -e "\n- All users' PASS_MAX_DAYS conform to the site policy."
  fi
}

# Function to apply remediation
remediate_pass_max_days() {
  echo "Applying remediation..."

  # Update PASS_MAX_DAYS in /etc/login.defs
  if grep -q "^PASS_MAX_DAYS" /etc/login.defs; then
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS 365/' /etc/login.defs
  else
    echo "PASS_MAX_DAYS 365" >> /etc/login.defs
  fi
  echo "PASS_MAX_DAYS set to 365 in /etc/login.defs."

  # Apply remediation to users
  for user in "${failed_users[@]}"; do
    echo "Setting PASS_MAX_DAYS to 365 days for user \"$user\"..."
    chage --maxdays 365 "$user"
  done

  echo "Remediation applied successfully."
}

# Main script execution
audit_pass_max_days
if [[ $? -ne 0 ]]; then
  audit_user_pass_max_days
  if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n) " choice
    if [[ "$choice" == "y" ]]; then
      remediate_pass_max_days
    else
      echo "Remediation skipped."
    fi
  fi
fi
