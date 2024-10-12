#!/usr/bin/env bash

# Function to check GRUB parameters for AppArmor
check_apparmor_parameters() {
    missing_apparmor=$(grep "^\s*linux" /boot/grub/grub.cfg | grep -v "apparmor=1")
    missing_security=$(grep "^\s*linux" /boot/grub/grub.cfg | grep -v "security=apparmor")

    if [[ -n "$missing_apparmor" ]]; then
        echo "Missing parameter: apparmor=1"
    else
        echo "AppArmor parameter is set correctly."
    fi

    if [[ -n "$missing_security" ]]; then
        echo "Missing parameter: security=apparmor"
    else
        echo "Security parameter is set correctly."
    fi

    # Return 0 if both parameters are set, otherwise return 1
    if [[ -n "$missing_apparmor" || -n "$missing_security" ]]; then
        return 1  # At least one parameter is missing
    else
        return 0  # Both parameters are set
    fi
}

# Function to remediate GRUB parameters
remediate_grub_parameters() {
    echo "Editing /etc/default/grub to add apparmor=1 and security=apparmor..."

    # Backup the original grub file
    cp /etc/default/grub /etc/default/grub.bak

    # Update the GRUB_CMDLINE_LINUX line to include required parameters
    sed -i 's/^GRUB_CMDLINE_LINUX=".*"/GRUB_CMDLINE_LINUX="apparmor=1 security=apparmor"/' /etc/default/grub

    # Update grub configuration
    update-grub

    echo "GRUB parameters updated successfully."
}

# Main script execution
check_apparmor_parameters
if [[ $? -ne 0 ]]; then
    read -p "Do you want to apply the remediation? (y/n): " user_choice
    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        remediate_grub_parameters
    else
        echo "Remediation aborted by the user."
    fi
else
    echo "No action needed. AppArmor parameters are correctly set."
fi
