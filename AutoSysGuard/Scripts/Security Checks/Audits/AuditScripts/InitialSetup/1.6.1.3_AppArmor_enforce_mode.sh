#!/bin/bash

# Function to check AppArmor profiles
check_apparmor_profiles() {
    echo "Checking AppArmor profiles..."

    # Check loaded profiles
    profiles_output=$(apparmor_status | grep profiles)
    echo "$profiles_output"

    # Check processes
    processes_output=$(apparmor_status | grep processes)
    echo "$processes_output"

    # Extract the counts
    loaded_profiles=$(echo "$profiles_output" | awk '{print $1}')
    enforce_profiles=$(echo "$profiles_output" | awk '{print $4}')
    complain_profiles=$(echo "$profiles_output" | awk '{print $6}')
    
    # Check unconfined processes
    unconfined_processes=$(echo "$processes_output" | grep "unconfined" | awk '{print $5}' | sed 's/[^0-9]*//g')
    if [ -z "$unconfined_processes" ]; then
        unconfined_processes=0
    fi

    # Display audit results
    echo -e "\nAudit Results:"
    echo "Loaded Profiles: $loaded_profiles"
    echo "Profiles in Enforce Mode: $enforce_profiles"
    echo "Profiles in Complain Mode: $complain_profiles"
    echo "Unconfined Processes: $unconfined_processes"

    # Check if there are unconfined processes
    if [ "$unconfined_processes" -gt 0 ]; then
        echo "Warning: There are $unconfined_processes unconfined processes!"
        return 1  # Indicate issues found
    else
        echo "All processes are confined."
        return 0  # Indicate no issues
    fi
}

# Function for remediation
apply_remediation() {
    echo "Choose remediation option:"
    echo "1. Set all profiles to enforce mode"
    echo "2. Set all profiles to complain mode"
    echo "3. Exit without making changes"

    read -rp "Enter your choice (1/2/3): " choice

    case $choice in
        1)
            echo "Setting all profiles to enforce mode..."
            sudo aa-enforce /etc/apparmor.d/*
            echo "All profiles set to enforce mode."
            ;;
        2)
            echo "Setting all profiles to complain mode..."
            sudo aa-complain /etc/apparmor.d/*
            echo "All profiles set to complain mode."
            ;;
        3)
            echo "Exiting without making changes."
            ;;
        *)
            echo "Invalid choice. Exiting."
            ;;
    esac
}

# Main script execution
check_apparmor_profiles
if [ $? -ne 0 ]; then
    read -rp "Would you like to apply remediation? (y/n): " apply
    if [[ "$apply" =~ ^[Yy]$ ]]; then
        apply_remediation
    else
        echo "No remediation applied."
    fi
else
    echo "No remediation needed."
fi
