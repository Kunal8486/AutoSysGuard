# 3.4.2.9 Ensure nftables service is enabled (Automated)
#!/bin/bash

# Function to check if nftables service is enabled
audit_nftables_service() {
  echo "Auditing nftables service status..."
  nftables_status=$(systemctl is-enabled nftables 2>/dev/null)

  if [[ "$nftables_status" == "enabled" ]]; then
    echo "nftables service is enabled."
    return 0
  else
    echo "nftables service is NOT enabled."
    return 1
  fi
}

# Function to apply remediation by enabling nftables service
apply_remediation() {
  echo "Applying remediation..."
  systemctl enable nftables
  if [[ $? -eq 0 ]]; then
    echo "nftables service has been successfully enabled."
  else
    echo "Failed to enable nftables service. Please check the service status."
  fi
}

# Audit nftables service status
audit_nftables_service
audit_result=$?

# Check if remediation is necessary
if [[ $audit_result -eq 1 ]]; then
  # Ask user for permission to apply remediation
  read -p "Would you like to enable the nftables service? (y/n): " choice

  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    apply_remediation
  else
    echo "Remediation skipped."
  fi
else
  echo "No remediation needed. The nftables service is already enabled."
fi
