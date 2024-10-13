#!/bin/bash

# 3.4.2.6 Ensure loopback traffic is configured

# Function to run the audit
run_audit() {
    echo "Starting audit of loopback interface configuration..."
    echo ""

    # Check if loopback interface is configured to accept traffic
    loopback_accept=$(nft list ruleset | awk '/hook input/,/}/' | grep 'iif "lo" accept')
    if [ -n "$loopback_accept" ]; then
        echo " - Loopback interface is accepting traffic: $loopback_accept"
    else
        echo " - ** FAIL ** Loopback interface is NOT accepting traffic!"
        audit_result="FAIL"
    fi

    # Check if IPv4 loopback traffic is configured to drop
    ipv4_drop=$(nft list ruleset | awk '/hook input/,/}/' | grep 'ip saddr 127.0.0.0/8 counter drop')
    if [ -n "$ipv4_drop" ]; then
        echo " - IPv4 loopback traffic is correctly configured to drop."
    else
        echo " - ** FAIL ** IPv4 loopback traffic is not configured to drop!"
        audit_result="FAIL"
    fi

    # Check if IPv6 is enabled, and if so, if traffic is configured to drop
    ipv6_enabled=$(sysctl net.ipv6.conf.all.disable_ipv6 | grep '0')
    if [ -n "$ipv6_enabled" ]; then
        ipv6_drop=$(nft list ruleset | awk '/hook input/,/}/' | grep 'ip6 saddr ::1 counter drop')
        if [ -n "$ipv6_drop" ]; then
            echo " - IPv6 loopback traffic is correctly configured to drop."
        else
            echo " - ** FAIL ** IPv6 loopback traffic is not configured to drop!"
            audit_result="FAIL"
        fi
    else
        echo " - IPv6 is disabled on this system."
    fi

    echo ""
    if [ "$audit_result" = "FAIL" ]; then
        echo "- Audit Result: ** FAIL **"
    else
        echo "- Audit Result: ** PASS **"
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Allow loopback interface traffic (if it doesn't already exist)
    loopback_rule=$(nft list ruleset | awk '/hook input/,/}/' | grep 'iif "lo" accept')
    if [ -z "$loopback_rule" ]; then
        sudo nft add rule inet filter input iif lo accept
        echo " - Added rule to allow loopback traffic."
    fi

    # Drop IPv4 loopback traffic (if it doesn't already exist)
    ipv4_drop_rule=$(nft list ruleset | awk '/hook input/,/}/' | grep 'ip saddr 127.0.0.0/8 counter drop')
    if [ -z "$ipv4_drop_rule" ]; then
        sudo nft add rule inet filter input ip saddr 127.0.0.0/8 counter drop
        echo " - Added rule to drop IPv4 loopback traffic."
    fi

    # Drop IPv6 loopback traffic (if it doesn't already exist and IPv6 is enabled)
    if [ -n "$ipv6_enabled" ]; then
        ipv6_drop_rule=$(nft list ruleset | awk '/hook input/,/}/' | grep 'ip6 saddr ::1 counter drop')
        if [ -z "$ipv6_drop_rule" ]; then
            sudo nft add rule inet filter input ip6 saddr ::1 counter drop
            echo " - Added rule to drop IPv6 loopback traffic."
        fi
    fi

    echo "Remediation applied. Re-running the audit..."
}

# Run the initial audit
audit_result="PASS"
run_audit

# Check if audit failed, then ask user for remediation
if [ "$audit_result" = "FAIL" ]; then
    read -p "Do you want to apply remediation? (y/n): " apply_fix
    if [ "$apply_fix" = "y" ]; then
        apply_remediation
        
        # Reset audit result and re-run audit
        audit_result="PASS"
        run_audit
    else
        echo "Remediation not applied."
    fi
else
    echo "No remediation needed. Audit passed."
fi
