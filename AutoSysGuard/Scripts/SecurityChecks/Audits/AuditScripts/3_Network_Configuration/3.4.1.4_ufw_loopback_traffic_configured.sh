#!/bin/bash

# Function to check UFW status and rules
check_audit() {
    echo "Running UFW status check..."
    ufw_output=$(ufw status verbose)

    # Print UFW status output for debugging
    echo "UFW Status Output:"
    echo "$ufw_output"
    echo

    # Define required rules
    required_rules=(
        "ALLOW IN Anywhere on lo"
        "DENY IN 127.0.0.0/8"
        "ALLOW IN Anywhere (v6) on lo"
        "DENY IN ::1"
        "ALLOW OUT Anywhere on lo"
        "ALLOW OUT Anywhere (v6) on lo"
    )

    all_rules_present=true

    # Check for each required rule
    for rule in "${required_rules[@]}"; do
        if ! echo "$ufw_output" | grep -q "$rule"; then
            all_rules_present=false
            echo "Missing rule: $rule"
        else
            echo "Found rule: $rule"
        fi
    done

    if $all_rules_present; then
        echo "All required rules are present."
    else
        echo "Not all required rules are present."
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Adding rules with checks to avoid duplicates
    # Check if rules already exist before adding them
    if ! ufw status | grep -q "ALLOW IN Anywhere on lo"; then
        ufw allow in on lo
    fi

    if ! ufw status | grep -q "DENY IN 127.0.0.0/8"; then
        ufw deny in from 127.0.0.0/8
    fi

    if ! ufw status | grep -q "ALLOW IN Anywhere (v6) on lo"; then
        ufw allow in on lo proto ipv6
    fi

    if ! ufw status | grep -q "DENY IN ::1"; then
        ufw deny in from ::1
    fi

    if ! ufw status | grep -q "ALLOW OUT Anywhere on lo"; then
        ufw allow out on lo
    fi

    if ! ufw status | grep -q "ALLOW OUT Anywhere (v6) on lo"; then
        ufw allow out on lo proto ipv6
    fi

    echo "Remediation applied."
}

# Main script execution
check_audit

# Prompt user for remediation
read -p "Do you want to apply remediation? (y/n): " user_input

if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
    apply_remediation
else
    echo "No remediation applied."
fi
