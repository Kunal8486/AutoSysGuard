# 3.4.2.4 Ensure a nftables table exists (Automated)
#!/bin/bash

# Function to audit nftables
audit_nftables() {
    echo "Checking if nftables tables exist..."
    NFTABLES_OUTPUT=$(nft list tables 2>/dev/null)

    if [[ -n "$NFTABLES_OUTPUT" ]]; then
        echo "nftables tables found:"
        echo "$NFTABLES_OUTPUT"
        return 0
    else
        echo "No nftables tables found."
        return 1
    fi
}

# Function to create a new nftables table
remediate_nftables() {
    echo "Please enter the table name you want to create in nftables (default: filter):"
    read -r TABLE_NAME
    TABLE_NAME=${TABLE_NAME:-filter}

    echo "Creating nftables table 'inet $TABLE_NAME'..."
    nft create table inet "$TABLE_NAME"
    
    if [[ $? -eq 0 ]]; then
        echo "Table 'inet $TABLE_NAME' created successfully."
    else
        echo "Failed to create table 'inet $TABLE_NAME'."
    fi
}

# Main audit and remediation logic
audit_and_remediate_nftables() {
    audit_nftables
    if [[ $? -ne 0 ]]; then
        echo "Would you like to create a new nftables table? (y/n)"
        read -r REPLY
        if [[ "$REPLY" == "y" ]]; then
            remediate_nftables
        else
            echo "Skipping nftables remediation."
        fi
    fi
}

# Run the audit and remediation process
audit_and_remediate_nftables
