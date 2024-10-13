#!/bin/bash

# Function to perform the audit
audit_sudo_timestamp_timeout() {
  echo "Auditing timestamp_timeout in /etc/sudoers*..."

  # Check if timestamp_timeout is configured in any sudoers file
  current_timeout=$(grep -roP "timestamp_timeout=\K[0-9]*" /etc/sudoers*)

  # If no timestamp_timeout is set, check the default using sudo -V
  if [ -z "$current_timeout" ]; then
    default_timeout=$(sudo -V | grep "Authentication timestamp timeout:" | awk '{print $5}')
    echo "No timestamp_timeout configured, default is $default_timeout minutes."

    # Default is 15 minutes, check if it's -1 or larger than 15
    if [ "$default_timeout" == "-1" ] || [ "$default_timeout" -gt 15 ]; then
      echo "Audit failed: Default timeout is larger than 15 minutes."
      return 1
    else
      echo "Audit passed: Default timeout is 15 minutes or less."
      return 0
    fi
  else
    # Check if the configured timeout is larger than 15
    if [ "$current_timeout" -gt 15 ]; then
      echo "Audit failed: Configured timestamp_timeout is $current_timeout minutes."
      return 1
    else
      echo "Audit passed: Configured timestamp_timeout is $current_timeout minutes."
      return 0
    fi
  fi
}

# Function to apply remediation
remediate_sudo_timestamp_timeout() {
  echo "Applying remediation..."

  # Backup the sudoers file
  cp /etc/sudoers /etc/sudoers.bak

  # Modify or add the timestamp_timeout setting
  if grep -q "timestamp_timeout=" /etc/sudoers; then
    # Update the existing timeout value
    sed -i 's/timestamp_timeout=[0-9]*/timestamp_timeout=15/' /etc/sudoers
  else
    # Add the timeout setting
    echo "Defaults timestamp_timeout=15" >> /etc/sudoers
  fi

  echo "Remediation applied: timestamp_timeout set to 15 minutes."
}

# Run the audit
audit_sudo_timestamp_timeout
audit_result=$?

# If the audit failed, ask for remediation
if [ $audit_result -ne 0 ]; then
  read -p "Audit failed. Do you want to apply remediation? (y/n): " user_input
  if [ "$user_input" == "y" ]; then
    remediate_sudo_timestamp_timeout
  else
    echo "Remediation skipped."
  fi
fi
