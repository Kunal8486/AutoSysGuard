# 3.4.1.6 Ensure ufw firewall rules exist for all open ports (Automated)
#!/usr/bin/env bash

# Function to perform the audit
perform_audit() {
    unset a_ufwout
    unset a_openports

    # Collect UFW open ports
    while read -r l_ufwport; do
        [ -n "$l_ufwport" ] && a_ufwout+=("$l_ufwport")
    done < <(ufw status verbose | grep -Po '^\h*\d+\b' | sort -u)

    # Collect open ports from listening services
    while read -r l_openport; do
        [ -n "$l_openport" ] && a_openports+=("$l_openport")
    done < <(ss -tuln | awk '($5!~/%lo:/ && $5!~/127.0.0.1:/ && $5!~/\[?::1\]?:/) {split($5, a, ":"); print a[2]}' | sort -u)

    # Find ports that are open but not in UFW rules
    a_diff=($(printf '%s\n' "${a_openports[@]}" "${a_ufwout[@]}" | sort | uniq -u))

    # Check if there are any discrepancies
    if [[ -n "${a_diff[*]}" ]]; then
        echo -e "\n- Audit Result:\n ** FAIL **\n- The following port(s) don't have a rule in UFW: $(printf '%s\n' \\n"${a_diff[@]}")\n- End List"
        return 1
    else
        echo -e "\n - Audit Passed -\n- All open ports have a rule in UFW\n"
        return 0
    fi
}

# Function to apply remediation
apply_remediation() {
    for port in "${a_diff[@]}"; do
        # Ask for the protocol
        read -p "Do you want to allow or deny inbound connections for port $port? (allow/deny): " action

        if [[ "$action" == "allow" ]]; then
            # Allow the port
            echo "Allowing inbound connections on port $port..."
            ufw allow in "$port"/tcp || ufw allow in "$port"/udp
        elif [[ "$action" == "deny" ]]; then
            # Deny the port
            echo "Denying inbound connections on port $port..."
            ufw deny in "$port"/tcp || ufw deny in "$port"/udp
        else
            echo "Invalid action for port $port. Skipping."
        fi
    done
}

# Main script execution
perform_audit
audit_result=$?

# If audit fails (i.e., missing rules), prompt for remediation
if [[ $audit_result -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
        echo "Remediation applied."
    else
        echo "No remediation applied."
    fi
fi
