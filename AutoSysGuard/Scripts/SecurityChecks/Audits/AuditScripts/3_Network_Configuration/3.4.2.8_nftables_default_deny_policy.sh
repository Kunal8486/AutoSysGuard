# 3.4.2.8 Ensure nftables default deny firewall policy (Automated)
#!/bin/bash

# Function to audit if a specific base chain has a DROP policy
audit_chain_policy() {
  local chain=$1
  local hook=$2
  echo "Auditing $chain base chain..."

  result=$(nft list ruleset | grep "hook $hook" | grep "policy drop")

  if [[ -n "$result" ]]; then
    echo "$chain base chain has a policy of DROP."
    return 0
  else
    echo "$chain base chain does NOT have a policy of DROP."
    return 1
  fi
}

# Function to apply the DROP policy to the base chain
apply_remediation() {
  echo "Applying remediation to set DROP policy on base chains..."

  # Apply DROP policy to input, forward, and output chains
  nft chain inet filter input { policy drop \; }
  nft chain inet filter forward { policy drop \; }
  nft chain inet filter output { policy drop \; }

  if [[ $? -eq 0 ]]; then
    echo "DROP policy applied to input, forward, and output chains."
  else
    echo "Failed to apply DROP policy. Please check your nftables configuration."
  fi
}

# Audit the input, forward, and output chains
audit_input=0
audit_forward=0
audit_output=0

audit_chain_policy "Input" "input"
audit_input=$?
echo ""
audit_chain_policy "Forward" "forward"
audit_forward=$?
echo ""
audit_chain_policy "Output" "output"
audit_output=$?
echo ""

# Check if any chain needs remediation
if [[ $audit_input -eq 1 || $audit_forward -eq 1 || $audit_output -eq 1 ]]; then
  echo "One or more base chains need remediation."

  # Ask user for permission to apply remediation
  read -p "Would you like to apply the DROP policy to the base chains? (y/n): " choice

  if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    apply_remediation
  else
    echo "Remediation skipped."
  fi
else
  echo "All base chains are configured with a DROP policy. No remediation needed."
fi
