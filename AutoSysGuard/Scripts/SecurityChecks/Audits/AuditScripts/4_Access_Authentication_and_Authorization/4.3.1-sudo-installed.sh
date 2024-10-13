#!/bin/bash

# Function to perform the audit
audit_sudo_package() {
  echo "Auditing sudo or sudo-ldap package installation..."

  # Check if sudo or sudo-ldap is installed
  dpkg-query -W sudo sudo-ldap > /dev/null 2>&1
  if dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' sudo sudo-ldap | awk '($4=="installed" && $NF=="installed") {print "\nPASS:\nPackage \""$1"\" is installed\n"}'; then
    return 0
  else
    echo -e "\nFAIL:\nneither \"sudo\" nor \"sudo-ldap\" package is installed\n"
    return 1
  fi
}

# Function to apply remediation
remediate_sudo_package() {
  echo "Applying remediation..."

  # Ask user if LDAP functionality is required
  read -p "Is LDAP functionality required? (y/n): " ldap_required
  if [ "$ldap_required" == "y" ]; then
    # Install sudo-ldap if LDAP is required
    apt install sudo-ldap -y
    echo "Remediation applied: sudo-ldap installed."
  else
    # Install sudo if LDAP is not required
    apt install sudo -y
    echo "Remediation applied: sudo installed."
  fi
}

# Run the audit
audit_sudo_package
audit_result=$?

# If the audit failed, ask for remediation
if [ $audit_result -ne 0 ]; then
  read -p "Audit failed. Do you want to apply remediation? (y/n): " user_input
  if [ "$user_input" == "y" ]; then
    remediate_sudo_package
  else
    echo "Remediation skipped."
  fi
fi
