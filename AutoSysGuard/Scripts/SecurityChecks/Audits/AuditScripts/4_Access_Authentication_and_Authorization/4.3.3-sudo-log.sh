#!/bin/bash

# Function to perform the audit
audit_sudo_logfile() {
  echo "Auditing sudo logfile configuration in /etc/sudoers*..."

  # Search for the logfile setting in sudoers files
  logfile_setting=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers*)

  # Verify if the logfile is set to /var/log/sudo.log
  if echo "$logfile_setting" | grep -q 'Defaults logfile="/var/log/sudo.log"'; then
    echo "Audit passed: Sudo is logging to /var/log/sudo.log."
    return 0
  else
    echo "Audit failed: Sudo logfile configuration is missing or incorrect."
    echo "Current configuration:"
    echo "$logfile_setting"
    return 1
  fi
}

# Function to apply remediation
remediate_sudo_logfile() {
  echo "Applying remediation..."

  # Backup the sudoers file
  cp /etc/sudoers /etc/sudoers.bak

  # Add the logfile setting to the sudoers file
  if ! grep -q 'Defaults logfile="/var/log/sudo.log"' /etc/sudoers; then
    echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
    echo "Remediation applied: Sudo log file set to /var/log/sudo.log."
  else
    echo "No changes needed, logfile setting already exists."
  fi
}

# Run the audit
audit_sudo_logfile
audit_result=$?

# If the audit failed, ask for remediation
if [ $audit_result -ne 0 ]; then
  read -p "Audit failed. Do you want to apply remediation? (y/n): " user_input
  if [ "$user_input" == "y" ]; then
    remediate_sudo_logfile
  else
    echo "Remediation skipped."
  fi
fi
