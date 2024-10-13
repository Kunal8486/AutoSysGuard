# 3.4.1.7 Ensure ufw default deny firewall policy (Automated)
#!/usr/bin/env bash

# Function to perform the audit
perform_audit() {
    # Get the current default policies
    default_policies=$(ufw status verbose | grep 'Default:')

    # Check for correct default policies
    if [[ "$default_policies" =~ "deny (incoming)" ]] && \
       [[ "$default_policies" =~ "deny (outgoing)" ]] && \
       [[ "$default_policies" =~ "disabled (routed)" ]]; then
        echo -e "\n- Audit Passed -\n- Default policies are set correctly:\n$default_policies\n"
        return 0
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n- Current default policies:\n$default_policies\n"
        return 1
    fi
}

# Function to apply remediation
apply_remediation() {
    echo "Applying default deny policy..."
    sudo ufw default deny incoming
    sudo ufw default deny outgoing
    sudo ufw default deny routed
    echo "Default deny policy applied successfully."
}

# Main script execution
perform_audit
audit_result=$?

# If audit fails, prompt for remediation
if [[ $audit_result -ne 0 ]]; then
    read -p "Do you want to apply remediation? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
fi
