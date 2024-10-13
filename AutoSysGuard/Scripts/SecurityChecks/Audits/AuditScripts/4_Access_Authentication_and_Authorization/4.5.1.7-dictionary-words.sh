#!/usr/bin/env bash

audit_pwquality_dictcheck() {
  # Check the current value of dictcheck in /etc/security/pwquality.conf
  echo "Performing audit for dictcheck in /etc/security/pwquality.conf..."
  dictcheck_value=$(grep -Pi '^\h*dictcheck\h*=\h*[^0]' /etc/security/pwquality.conf)

  if [[ -n "$dictcheck_value" ]]; then
    echo "Audit Result: **PASS** - dictcheck is correctly set."
    echo "$dictcheck_value"
  else
    echo "Audit Result: **FAIL** - dictcheck is not set correctly."
    echo "Do you want to apply remediation? (y/n)"
    read -r user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
      apply_remediation
    else
      echo "Remediation not applied."
    fi
  fi
}

apply_remediation() {
  # Apply the remediation to set dictcheck = 1
  echo "Applying remediation..."
  if grep -Pi '^\h*dictcheck' /etc/security/pwquality.conf > /dev/null; then
    sed -i 's/^\h*dictcheck\h*=.*/dictcheck = 1/' /etc/security/pwquality.conf
    echo "Updated dictcheck to 1 in /etc/security/pwquality.conf."
  else
    echo "dictcheck = 1" >> /etc/security/pwquality.conf
    echo "Added dictcheck = 1 to /etc/security/pwquality.conf."
  fi
  echo "Remediation applied successfully."
}

# Run the audit
audit_pwquality_dictcheck
