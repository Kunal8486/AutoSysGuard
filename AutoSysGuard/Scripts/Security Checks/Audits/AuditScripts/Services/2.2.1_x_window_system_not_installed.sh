# 2.2.1 Ensure X Window System is not installed (Automated)
#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Audit: Check if X Window System is installed
echo "Checking if X Window System is installed..."
x_window_installed=$(dpkg-query -W -f='${binary:Package}\t${Status}\n' | grep -Pi 'xserver-xorg.*installed')

if [ -z "$x_window_installed" ]; then
    echo "Audit passed: X Window System is not installed."
else
    echo "Audit failed: X Window System is installed."
    echo "$x_window_installed"
    echo "Would you like to apply remediation? (y/n)"
    read -r remediation_choice
    if [[ "$remediation_choice" == "y" || "$remediation_choice" == "Y" ]]; then
        # Remediation: Remove the X Window System packages
        echo "Applying remediation..."
        sudo apt purge -y xserver-xorg*
        echo "X Window System packages have been removed."
    else
        echo "Remediation skipped. X Window System remains installed."
    fi
fi
