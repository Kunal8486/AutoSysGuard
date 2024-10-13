#!/bin/bash

# Function to perform the audit
audit_sudo_nopasswd() {
  echo "Auditing for NOPASSWD tag in /etc/sudoers*..."

  # Search for NOPASSWD in sudoers files
  nopasswd_lines=$(grep -r "^[^#].*NOPASSWD" /etc/sudoers*)

  # Check if any line contains NOPASSWD
  if [ -n "$nopasswd_lines" ]; then
    echo "Audit failed: NOPASSWD found in the following lines:"
    echo "$nopasswd_lines"
    return 1
  else
    echo "Audit passed: No NOPASSWD tags found."
    return 0
  fi
}

# Function to apply remediation
remediate_sudo_nopasswd() {
  echo "Applying remediation..."

  # Backup sudoers file
  cp /etc/sudoers /etc/sudoers.bak

  # Remove NOPASSWD from sudoers files
  for file in /etc/sudoers /etc/sudoers.d/*; do
    if [ -f "$file" ]; then
      sed -i '/^[^#].*NOPASSWD/d' "$file"
      echo "Remediation applied to $file: NOPASSWD tags removed."
    fi
  done
}

# Run the audit
audit_sudo_nopasswd
audit_result=$?

# If the audit failed, ask for remediation
if [ $audit_result -ne 0 ]; then
  read -p "Audit failed. Do you want to apply remediation? (y/n): " user_input
  if [ "$user_input" == "y" ]; then
    remediate_sudo_nopasswd
  else
    echo "Remediation skipped."
  fi
fi
