#!/usr/bin/env bash

# Function to check the PASS_WARN_AGE in /etc/login.defs
audit_pass_warn_age() {
  echo "Performing audit for PASS_WARN_AGE (no less than 7 days)..."
  
  # Check PASS_WARN_AGE value in /etc/login.defs
  pass_warn_age=$(grep -E "^PASS_WARN_AGE\s+[0-9]+" /etc/login.defs | awk '{print $2}')
  
  if [[ -z "$pass_warn_age" || "$pass_warn_age" -lt 7 ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **\n - PASS_WARN_AGE is less than 7 days or not set correctly."
    return 1
  else
    echo -e "\n- Audit Result:\n ** PASS **\n - PASS_WARN_AGE is correctly set to $pass_warn_age days."
  fi
}

# Function to check PASS_WARN_AGE for individual users
audit_user_pass_warn_age() {
  failed_users=()
  while IFS=: read -r user pass uid gid gecos home shell; do
    if [[ "$pass" != "*" && "$pass" != "!" && "$pass" != "" ]]; then
      user_warn_age=$(chage --list "$user" | awk -F: '/^Password expires/ {print $2}')
      if [[ -n "$user_warn_age" && "$user_warn_age" -lt 7 ]]; then
        failed_users+=("$user")
      fi
    fi
  done < /etc/shadow

  if [[ ${#failed_users[@]} -gt 0 ]]; then
    echo -e "\n- Audit Result:\n ** FAIL **"
    echo "- The following users have PASS_WARN_AGE set to less than 7 days:"
    for user in "${failed_users[@]}"; do
      echo "  - User: $user"
    done
    return 1
  else
    echo -e "\n- All users' PASS_WARN_AGE conforms to the site policy."
  fi
}

# Function to apply remediation
remediate_pass_warn_age() {
  echo "Applying remediation..."

  # Update PASS_WARN_AGE in /etc/login.defs
  if grep -q "^PASS_WARN_AGE" /etc/login.defs; then
    sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
  else
    echo "PASS_WARN_AGE 7" >> /etc/login.defs
  fi
  echo "PASS_WARN_AGE set to 7 in /etc/login.defs."

  # Apply remediation to users
  for user in "${failed_users[@]}"; do
    echo "Setting PASS_WARN_AGE to 7 days for user \"$user\"..."
    chage --warndays 7 "$user"
  done

  echo "Remediation applied successfully."
}

# Main script execution
audit_pass_warn_age
if [[ $? -ne 0 ]]; then
  audit_user_pass_warn_age
  if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n) " choice
    if [[ "$choice" == "y" ]]; then
      remediate_pass_warn_age
    else
      echo "Remediation skipped."
    fi
  fi
fi
