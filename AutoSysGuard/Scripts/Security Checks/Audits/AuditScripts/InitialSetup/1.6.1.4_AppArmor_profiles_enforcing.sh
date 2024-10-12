#!/bin/bash

# Function to check if apparmor is installed
check_apparmor_installed() {
    if ! command -v apparmor_status &> /dev/null; then
        echo "AppArmor is not installed. Please install it and run the script again."
        exit 1
    fi
}

# Function to check AppArmor profile status
audit_apparmor_profiles() {
    echo "Auditing AppArmor profiles..."
    local loaded_profiles=$(apparmor_status | grep "profiles are loaded")
    local enforce_profiles=$(apparmor_status | grep "profiles are in enforce mode")
    local complain_profiles=$(apparmor_status | grep "profiles are in complain mode")
    local unconfined_processes=$(apparmor_status | grep "processes are unconfined")
    
    echo "$loaded_profiles"
    echo "$enforce_profiles"
    echo "$complain_profiles"
    
    if [ -n "$unconfined_processes" ]; then
        echo "$unconfined_processes"
    else
        echo "No unconfined processes found."
    fi
}

# Function to apply remediation if user confirms
apply_remediation() {
    read -p "Would you like to apply remediation and enforce all profiles? (y/n): " response
    case $response in
        [Yy]* )
            echo "Applying remediation..."
            sudo aa-enforce /etc/apparmor.d/*
            echo "Remediation applied. All profiles are now in enforce mode."
            ;;
        [Nn]* )
            echo "Remediation not applied."
            ;;
        * )
            echo "Invalid response. Please enter y or n."
            apply_remediation
            ;;
    esac
}

# Main logic
check_apparmor_installed
audit_apparmor_profiles
apply_remediation
