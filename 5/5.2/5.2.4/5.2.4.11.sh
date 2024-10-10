#!/bin/bash

# Check if AIDE is installed
if ! command -v aide &> /dev/null; then
    echo "AIDE is not installed. Please install it to continue."
    exit 1
fi

# Define the AIDE configuration files
AIDE_CONFIG_FILES="/etc/aide.conf /etc/aide/aide.conf /etc/aide.conf.d/*.conf /etc/aide/aide.conf.d/*"

# Check for cryptographic configurations for audit tools
echo "Checking AIDE configuration for audit tools..."
if ! grep -Ps -- '(\/sbin\/(audit|au)\H*\b)' $AIDE_CONFIG_FILES > /dev/null; then
    echo "No cryptographic configurations found for audit tools."
    echo "Adding required configurations..."

    # Create or append the audit tools configuration
    CONFIG_FILE="/etc/aide/aide.conf.d/audit_tools.conf"
    echo "# Audit Tools" | sudo tee $CONFIG_FILE
    echo "/sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a $CONFIG_FILE
    echo "/sbin/auditd p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a $CONFIG_FILE
    echo "/sbin/ausearch p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a $CONFIG_FILE
    echo "/sbin/aureport p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a $CONFIG_FILE
    echo "/sbin/autrace p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a $CONFIG_FILE
    echo "/sbin/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512" | sudo tee -a $CONFIG_FILE

    echo "Configurations added to $CONFIG_FILE."
else
    echo "AIDE is already configured to use cryptographic mechanisms for audit tools."
fi

# Initialize or update the AIDE database
echo "Initializing AIDE database..."
sudo aideinit

# Move the new AIDE database into place
echo "Updating AIDE database..."
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Run AIDE check
echo "Running AIDE check..."
sudo aide --check

echo "Audit tool integrity check completed."
