# 3.4.2.5 Ensure nftables base chains exist (Automated)
#!/bin/bash

# Function to check if a base chain exists
check_base_chain() {
    local chain_type=$1
    if nft list ruleset | grep -q "hook $chain_type"; then
        echo "$chain_type chain exists."
        return 0
    else
        echo "$chain_type chain is missing."
        return 1
    fi
}

# Function to prompt user for remediation and apply if confirmed
apply_remediation() {
    local table_name="filter"
    local chain_name=$1
    local chain_hook=$2

    read -p "Would you like to create the $chain_name chain? (y/n): " response
    if [[ "$response" == "y" ]]; then
        nft create chain inet $table_name $chain_name "{ type filter hook $chain_hook priority 0 ; }"
        echo "$chain_name chain created."
    else
        echo "Remediation skipped for $chain_name chain."
    fi
}

# Check base chains for INPUT, FORWARD, and OUTPUT
missing_chains=()

check_base_chain "input"
if [ $? -ne 0 ]; then
    missing_chains+=("input")
fi

check_base_chain "forward"
if [ $? -ne 0 ]; then
    missing_chains+=("forward")
fi

check_base_chain "output"
if [ $? -ne 0 ]; then
    missing_chains+=("output")
fi

# Apply remediation if any base chains are missing
if [ ${#missing_chains[@]} -eq 0 ]; then
    echo "All base chains are present. No remediation needed."
else
    for chain in "${missing_chains[@]}"; do
        apply_remediation "$chain" "$chain"
    done
fi
