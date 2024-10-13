#!/bin/bash

# Function to perform the audit
audit_sudo_use_pty() {
  echo "Auditing sudo use_pty configuration in /etc/sudoers*..."

  # Search for use_pty setting in sudoers files
  use_pty_setting=$(grep -rPi '^\h*Defaults\h+([^#\n\r]+,)?use_pty(,\h*\h+\h*)*\h*(#.*)?$' /etc/sudoers*)

  # Verify if use_pty is configured
  if echo "$use_pty_setting" | grep -q 'Defaults use_pty'; then
    echo "Audit passed: sudo is configured to use a pseudo terminal (use_pty)."
    return 0
  else
    echo "Audit failed: sudo is not properly configured with use_pty."
    echo "Current configuration:"
    echo "$use_pty_setting"
    return 1
  fi
}

# Function to apply remediation
remediate_sudo_use_pty() {
  echo "Applying remediation..."

  # Backup the sudoers file
  cp /etc/sudoers /etc/sudoers.bak

  # Add use_pty setting to sudoers file
  if ! grep -q 'Defaults use_pty' /etc/sudoers; then
    echo 'Defaults use_pty' >> /etc/sudoers
    echo "Remediation applied: sudo now requires a pseudo terminal (use_pty)."
  else
    echo "No changes needed, use_pty setting already exists."
  fi
}

# Run the audit
audit_sudo_use_pty
audit_result=$?

# If the audit failed, ask for remediation
if [ $audit_result -ne 0 ]; then
  read -p "Audit failed. Do you want to apply remediation? (y/n): " user_input
  if [ "$user_input" == "y" ]; then
    remediate_sudo_use_pty
  else
    echo "Remediation skipped."
  fi
fi
