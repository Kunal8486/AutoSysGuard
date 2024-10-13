#!/usr/bin/env bash

audit_pwquality_difok() {
  # Check if difok is set to 2 or more
  echo "Performing audit for difok in /etc/security/pwquality.conf..."
  difok_value=$(grep -P '^\h*difok\h*=\h*([2-9]|[1-9][0-9]+)\b' /etc/security/pwquality.conf)

  if [[ -n "$difok_value" ]]; then
    echo "Audit Result: **PASS** - difok is set to 2 or more."
    echo "$difok_value"
  else
    echo "Audit Result: **FAIL** - difok is not set to 2 or more."
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
  # Apply the remediation to set difok = 2
  echo "Applying remediation..."
  if grep -P '^\h*difok' /etc/security/pwquality.conf > /dev/null; then
    sed -i 's/^\h*difok\h*=.*/difok = 2/' /etc/security/pwquality.conf
    echo "Updated difok to 2 in /etc/security/pwquality.conf."
  else
    echo "difok = 2" >> /etc/security/pwquality.conf
    echo "Added difok = 2 to /etc/security/pwquality.conf."
  fi
  echo "Remediation applied successfully."
}

# Run the audit
audit_pwquality_difok
