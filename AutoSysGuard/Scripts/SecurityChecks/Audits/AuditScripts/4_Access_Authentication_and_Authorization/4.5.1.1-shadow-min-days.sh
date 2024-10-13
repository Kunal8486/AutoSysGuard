#!/usr/bin/env bash

# Function to check the PASS_MIN_DAYS in /etc/login.defs
audit_pass_min_days() {
  echo "Performing audit for PASS_MIN_DAYS (no less than 1 day)..."

  # Check PASS_MIN_DAYS value in /etc/login.defs
  pass_min_days=$(grep -E "^PASS_MIN_DAYS\s+[0-9]+" /etc/login.defs | awk '{print $2}')

  if [[ -z "$pass_min_days" || "$pass_min_days" -lt 1 ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **\n - PASS_MIN_DAYS is not set or is less than 1 day."
    return 1
  else
    echo -e "\n- Audit Result:\n ** PASS **\n - PASS_MIN_DAYS is correctly set to $pass_min_days days."
  fi
}

# Function to check PASS_MIN_DAYS for individual users
audit_user_pass_min_days() {
  failed_users=()
  while IFS=: read -r user pass uid gid gecos home shell; do
    if [[ "$pass" != "*" && "$pass" != "!" && "$pass" != "" ]]; then
      user_min_days=$(chage --list "$user" | awk -F: '/^Minimum/ {print $2}' | xargs)

      if [[ -n "$user_min_days" && "$user_min_days" -lt 1 ]]; then
        failed_users+=("$user")
      fi
    fi
  done < /etc/shadow

  if [[ ${#failed_users[@]} -gt 0 ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo "- The following users have PASS_MIN_DAYS less than 1 day:"
    for user in "${failed_users[@]}"; do
      echo "  - User: $user"
    done
    return 1
  else
    echo -e "\n- All users' PASS_MIN_DAYS conform to the site policy."
  fi
}

# Function to apply remediation
remediate_pass_min_days() {
  echo "Applying remediation..."

  # Update PASS_MIN_DAYS in /etc/login.defs
  if grep -q "^PASS_MIN_DAYS" /etc/login.defs; then
    sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS 1/' /etc/login.defs
  else
    echo "PASS_MIN_DAYS 1" >> /etc/login.defs
  fi
  echo "PASS_MIN_DAYS set to 1 in /etc/login.defs."

  # Apply remediation to users
  for user in "${failed_users[@]}"; do
    echo "Setting PASS_MIN_DAYS to 1 day for user \"$user\"..."
    chage --mindays 1 "$user"
  done

  echo "Remediation applied successfully."
}

# Main script execution
audit_pass_min_days
if [[ $? -ne 0 ]]; then
  audit_user_pass_min_days
  if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n) " choice
    if [[ "$choice" == "y" ]]; then
      remediate_pass_min_days
    else
      echo "Remediation skipped."
    fi
  fi
fi
