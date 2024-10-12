#!/bin/bash

# Check if chrony is installed
if ! command -v chronyd &> /dev/null; then
    echo "Chrony is not installed on this system."
    echo "If another time synchronization service is in use, please remove chrony."
    sudo apt purge chrony
    exit 1
fi

# Check for server and pool directives
echo "Checking for chrony server and pool directives..."
server_count=$(grep -Pr --include=*.{sources,conf} '^\h*server\h+' /etc/chrony/ | wc -l)
pool_count=$(grep -Pr --include=*.{sources,conf} '^\h*pool\h+' /etc/chrony/ | wc -l)

echo "Server directives found: $server_count"
echo "Pool directives found: $pool_count"

if [[ $server_count -lt 3 && $pool_count -eq 0 ]]; then
    echo "Audit failed: Check failed for server and/or pool directives."
    read -p "Do you want to apply remediation? (y/n): " answer
    if [[ "$answer" == "y" ]]; then
        echo "Creating a backup of the configuration file..."
        sudo cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak
        echo "You will now be prompted to edit the chrony configuration."
        nano /etc/chrony/chrony.conf  # or use your preferred text editor
        
        # Check if the user edited the file
        if [[ $? -eq 0 ]]; then
            echo "Changes saved. Restarting chronyd service to apply changes..."
            if systemctl list-units --full -all | grep -Fq 'chronyd.service'; then
                sudo systemctl restart chronyd
                echo "Chronyd service restarted."
            else
                echo "Chronyd service not found. Please check if Chrony is installed correctly."
            fi
        else
            echo "No changes were made to the configuration file."
        fi
    else
        echo "Remediation not applied."
    fi
else
    echo "Audit passed: Correct server and pool directives are in place."
fi

