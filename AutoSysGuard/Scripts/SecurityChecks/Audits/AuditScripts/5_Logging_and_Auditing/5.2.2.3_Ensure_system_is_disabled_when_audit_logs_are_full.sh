#!/bin/bash

# Desired settings for auditd configuration
DESIRED_SPACE_LEFT_ACTION="email"
DESIRED_ACTION_MAIL_ACCT="root"
DESIRED_ADMIN_SPACE_LEFT_ACTION="halt" # or "single"

# Function to audit the auditd configuration
audit_auditd_configuration() {
    echo "Auditing auditd configuration..."

    # Check space_left_action
    local space_left_action=$(grep -E '^\s*space_left_action\s*=' /etc/audit/auditd.conf | awk -F '=' '{print $2}' | xargs)
    if [[ "$space_left_action" != "$DESIRED_SPACE_LEFT_ACTION" ]]; then
        echo "Audit Failed: space_left_action is not set to '$DESIRED_SPACE_LEFT_ACTION'. Current: $space_left_action"
    fi

    # Check action_mail_acct
    local action_mail_acct=$(grep -E '^\s*action_mail_acct\s*=' /etc/audit/auditd.conf | awk -F '=' '{print $2}' | xargs)
    if [[ "$action_mail_acct" != "$DESIRED_ACTION_MAIL_ACCT" ]]; then
        echo "Audit Failed: action_mail_acct is not set to '$DESIRED_ACTION_MAIL_ACCT'. Current: $action_mail_acct"
    fi

    # Check admin_space_left_action
    local admin_space_left_action=$(grep -E '^\s*admin_space_left_action\s*=' /etc/audit/auditd.conf | awk -F '=' '{print $2}' | xargs)
    if [[ "$admin_space_left_action" != "halt" && "$admin_space_left_action" != "single" ]]; then
        echo "Audit Failed: admin_space_left_action is not set to 'halt' or 'single'. Current: $admin_space_left_action"
    fi

    # Determine overall audit status
    if [[ "$space_left_action" == "$DESIRED_SPACE_LEFT_ACTION" && \
          "$action_mail_acct" == "$DESIRED_ACTION_MAIL_ACCT" && \
          ( "$admin_space_left_action" == "halt" || "$admin_space_left_action" == "single" ) ]]; then
        echo "Audit Passed: auditd configuration is correct."
        return 0  # Audit passed
    else
        echo "Audit Failed: One or more settings are incorrect."
        return 1  # Audit failed
    fi
}

# Function to ask user for remediation
ask_for_remediation() {
    read -p "Do you want to apply remediation? (y/n): " answer
    case $answer in
        [Yy]* ) apply_remediation ;;
        [Nn]* ) echo "No remediation applied." ;;
        * ) echo "Invalid input. No remediation applied." ;;
    esac
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."

    # Backup existing auditd configuration
    cp /etc/audit/auditd.conf /etc/audit/auditd.conf.bak

    # Set space_left_action and action_mail_acct
    sed -i "s/^\s*space_left_action\s*=.*/space_left_action = $DESIRED_SPACE_LEFT_ACTION/" /etc/audit/auditd.conf
    sed -i "s/^\s*action_mail_acct\s*=.*/action_mail_acct = $DESIRED_ACTION_MAIL_ACCT/" /etc/audit/auditd.conf

    # Set admin_space_left_action to desired value if not present or incorrect
    if grep -q '^\s*admin_space_left_action\s*=' /etc/audit/auditd.conf; then
        sed -i "s/^\s*admin_space_left_action\s*=.*/admin_space_left_action = $DESIRED_ADMIN_SPACE_LEFT_ACTION/" /etc/audit/auditd.conf
    else
        echo "admin_space_left_action = $DESIRED_ADMIN_SPACE_LEFT_ACTION" >> /etc/audit/auditd.conf
    fi

    # Restart the auditd service to apply changes
    systemctl restart auditd
    echo "Remediation applied: auditd configuration updated and auditd service restarted."

    # Re-run audit to confirm the changes
    if audit_auditd_configuration; then
        echo "Audit Passed: auditd configuration is now set correctly."
    else
        echo "Audit Failed after remediation. Please check the configuration."
    fi
}

# Main script execution
if audit_auditd_configuration; then
    # Audit passed
    echo "Audit log configuration is correctly set."
else
    # Audit failed, ask for remediation
    ask_for_remediation
fi
