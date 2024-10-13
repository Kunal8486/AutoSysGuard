#!/bin/bash

# Function to check iptables rules
audit_iptables() {
    echo "Checking iptables rules..."
    IPTABLES_OUTPUT=$(iptables -L)

    if [[ "$IPTABLES_OUTPUT" == "Chain INPUT (policy ACCEPT)"* ]]; then
        echo "No iptables rules found."
    else
        echo "iptables rules found:"
        echo "$IPTABLES_OUTPUT"
        return 1
    fi
}

# Function to check ip6tables rules
audit_ip6tables() {
    echo "Checking ip6tables rules..."
    IP6TABLES_OUTPUT=$(ip6tables -L)

    if [[ "$IP6TABLES_OUTPUT" == "Chain INPUT (policy ACCEPT)"* ]]; then
        echo "No ip6tables rules found."
    else
        echo "ip6tables rules found:"
        echo "$IP6TABLES_OUTPUT"
        return 1
    fi
}

# Function to flush iptables rules
remediate_iptables() {
    echo "Flushing iptables rules..."
    iptables -F
    echo "iptables rules flushed."
}

# Function to flush ip6tables rules
remediate_ip6tables() {
    echo "Flushing ip6tables rules..."
    ip6tables -F
    echo "ip6tables rules flushed."
}

# Main audit and remediation logic
audit_and_remediate() {
    audit_iptables
    IPTABLES_AUDIT=$?

    audit_ip6tables
    IP6TABLES_AUDIT=$?

    if [[ $IPTABLES_AUDIT -ne 0 ]]; then
        echo "Would you like to flush iptables rules? (y/n)"
        read -r REPLY
        if [[ "$REPLY" == "y" ]]; then
            remediate_iptables
        else
            echo "Skipping iptables remediation."
        fi
    fi

    if [[ $IP6TABLES_AUDIT -ne 0 ]]; then
        echo "Would you like to flush ip6tables rules? (y/n)"
        read -r REPLY
        if [[ "$REPLY" == "y" ]]; then
            remediate_ip6tables
        else
            echo "Skipping ip6tables remediation."
        fi
    fi
}

# Run the audit and remediation process
audit_and_remediate
