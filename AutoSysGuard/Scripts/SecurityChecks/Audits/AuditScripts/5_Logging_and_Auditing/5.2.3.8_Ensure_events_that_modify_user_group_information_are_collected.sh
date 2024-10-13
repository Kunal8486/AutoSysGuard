#!/bin/bash

# Function to check the audit configuration
check_audit_rules() {
    # Check on disk configuration
    echo "Checking on disk configuration..."
    on_disk_output=$(awk '/^ *-w/ \
    &&(/\/etc\/group/ \
    ||/\/etc\/passwd/ \
    ||/\/etc\/gshadow/ \
    ||/\/etc\/shadow/ \
    ||/\/etc\/security\/opasswd/) \
    &&/ +-p *wa/ \
    &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)' /etc/audit/rules.d/*.rules)

    echo "On disk configuration output:"
    echo "$on_disk_output"

    # Expected rules
    expected_rules="\
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity"

    if [[ "$on_disk_output" == *"$expected_rules"* ]]; then
        echo "On disk configuration is correct."
    else
        echo "On disk configuration is incorrect."
        return 1
    fi

    # Check running configuration
    echo "Checking running configuration..."
    running_output=$(auditctl -l | awk '/^ *-w/ \
    &&(/\/etc\/group/ \
    ||/\/etc\/passwd/ \
    ||/\/etc\/gshadow/ \
    ||/\/etc\/shadow/ \
    ||/\/etc\/security\/opasswd/) \
    &&/ +-p *wa/ \
    &&(/ key= *[!-~]* *$/||/ -k *[!-~]* *$/)')

    echo "Running configuration output:"
    echo "$running_output"

    if [[ "$running_output" == *"$expected_rules"* ]]; then
        echo "Running configuration is correct."
    else
        echo "Running configuration is incorrect."
        return 1
    fi

    return 0
}

# Function to apply remediation
apply_remediation() {
    echo "Applying remediation..."
    printf "\
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
" >> /etc/audit/rules.d/50-identity.rules

    augenrules --load

    # Check if a reboot is required
    if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
        echo "Reboot required to load rules."
    else
        echo "Rules loaded successfully."
    fi
}

# Main script execution
check_audit_rules
audit_check_result=$?

if [[ $audit_check_result -ne 0 ]]; then
    read -p "Do you want to apply the remediation? (y/n): " user_input
    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
else
    echo "Audit checks passed. No action required."
fi
