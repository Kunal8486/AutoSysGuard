#!/bin/bash

# Function to audit shadowed passwords
audit_shadowed_passwords() {
  echo "Checking for accounts that do not use shadowed passwords..."
  
  # Run the audit command to find accounts without shadowed passwords
  non_shadowed_accounts=$(awk -F: '($2 != "x") { print $1 " is not set to shadowed passwords" }' /etc/passwd)

  # Check if any non-shadowed accounts were found
  if [[ -z "$non_shadowed_accounts" ]]; then
    echo "All accounts are set to use shadowed passwords."
  else
    echo "The following accounts do not use shadowed passwords:"
    echo "$non_shadowed_accounts"
    
    # Prompt for remediation
    read -p "Would you like to remediate this by setting accounts to use shadowed passwords? (y/n): " response
    if [[ "$response" == "y" ]]; then
      remediate_non_shadowed_passwords
    else
      echo "No changes have been made."
    fi
  fi
}

# Function to remediate non-shadowed passwords
remediate_non_shadowed_passwords() {
  echo "Remediating non-shadowed passwords..."
  
  # Backup /etc/passwd before making changes
  cp /etc/passwd /etc/passwd.bak
  
  # Set accounts to use shadowed passwords
  sed -e 's/^\([a-zA-Z0-9_]*\):[^:]*:/\1:x:/' -i /etc/passwd
  
  echo "Accounts have been set to use shadowed passwords."
  echo "Please investigate any accounts that were modified to determine their usage."
}

# Execute the audit function
audit_shadowed_passwords
