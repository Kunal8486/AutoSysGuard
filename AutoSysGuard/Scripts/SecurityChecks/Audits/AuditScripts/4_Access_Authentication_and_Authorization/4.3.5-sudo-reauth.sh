#!/bin/bash

# Function to perform the audit
audit_sudo_authenticate() {
  echo "Auditing for !authenticate tag in /etc/sudoers*..."

  # Search for !authenticate in sudoers files
  authenticate_lines=$(grep -r "^[^#].*\!authenticate" /etc/sudoers*)

  # Check if any line contains !authenticate
  if [ -n "$authenticate_lines" ]; then
    echo "Audit failed: !authenticate found in the following lines:"
    echo "$authenticate_lines"
    return 1
  else
    echo "Audit passed: No !authenticate tags found."
    return 0
  fi
}

# Function to apply remediation
remediate_sudo_authenticate() {
  echo "Applying remediation..."

  # Backup sudoers file
  cp /etc/sudoers /etc/sudoers.bak

  # Remove !authenticate from sudoers files
  for file in /etc/sudoers /etc/sudoers.d/*; do
    if [ -f "$file" ]; then
      sed -i '/^[^#].*\!authenticate/d' "$file"
      echo "Remediation applied to $file: !authenticate tags removed."
    fi
  done
}

# Run the audit
audit_sudo_authenticate
audit_result=$?

# If the audit failed, ask for remediation
if [ $audit_result -ne 0 ]; then
  read -p "Audit failed. Do you want to apply remediation? (y/n): " user_input
  if [ "$user_input" == "y" ]; then
    remediate_sudo_authenticate
  else
    echo "Remediation skipped."
  fi
fi
