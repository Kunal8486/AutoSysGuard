# 3.4.2.2 Ensure ufw is uninstalled or disabled with nftables (Automated)
#!/usr/bin/env bash

# Function to perform the audit
perform_audit() {
    # Check if ufw is installed
    if dpkg-query -W -f='${binary:Package}\t${Status}\t${db:Status-Status}\n' ufw 2>/dev/null | grep -q 'no packages found'; then
        echo -e "\n- Audit Passed -\n- ufw is not installed.\n"
        return 0
    fi

    # Check if ufw is inactive
    if ufw status | grep -q 'inactive'; then
        echo -e "\n- Audit Passed -\n- ufw is installed and inactive.\n"
        return 0
    fi

    # Check if ufw service is masked
    if systemctl is-enabled ufw.service | grep -q 'masked'; then
        echo -e "\n- Audit Passed -\n- ufw service is masked.\n"
        return 0
    fi

    # If none of the above checks pass, audit fails
    echo -e "\n- Audit Result:\n ** FAIL **\n- ufw is installed and active or enabled.\n"
    return 1
}

# Function to apply remediation
apply_remediation() {
    echo "What action do you want to take?"
    echo "1. Remove ufw"
    echo "2. Disable and mask ufw service"
    read -p "Please enter your choice (1 or 2): " choice

    case $choice in
        1)
            echo "Removing ufw..."
            sudo apt purge -y ufw
            if [[ $? -eq 0 ]]; then
                echo "ufw removed successfully."
            else
                echo "Failed to remove ufw."
            fi
            ;;
        2)
            echo "Disabling and masking ufw service..."
            sudo ufw disable
            sudo systemctl stop ufw.service
            sudo systemctl mask ufw.service
            if [[ $? -eq 0 ]]; then
                echo "ufw disabled and masked successfully."
            else
                echo "Failed to disable and mask ufw."
            fi
            ;;
        *)
            echo "Invalid choice. No action taken."
            ;;
    esac
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
