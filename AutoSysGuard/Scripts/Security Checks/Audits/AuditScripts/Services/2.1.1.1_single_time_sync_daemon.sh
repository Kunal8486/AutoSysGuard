#!/usr/bin/env bash

{
    output=""
    l_tsd=""
    l_sdtd=""
    l_chrony=""
    l_ntp=""

    # Check for installed time synchronization daemons
    dpkg-query -W chrony > /dev/null 2>&1 && l_chrony="y"
    dpkg-query -W ntp > /dev/null 2>&1 && l_ntp="y" || l_ntp=""
    systemctl list-units --all --type=service | grep -q 'systemd-timesyncd.service' && systemctl is-enabled systemd-timesyncd.service | grep -q 'enabled' && l_sdtd="y"

    # Determine which daemon is in use
    if [[ "$l_chrony" = "y" ]]; then
        l_tsd="chrony"
        output="$output\n- chrony is in use on the system"
    elif [[ "$l_ntp" = "y" ]]; then
        l_tsd="ntp"
        output="$output\n- ntp is in use on the system"
    elif [[ "$l_sdtd" = "y" ]]; then
        l_tsd="sdtd"
        output="$output\n- systemd-timesyncd is in use on the system"
    fi

    # Output results
    if [ -n "$l_tsd" ]; then
        echo -e "\n- PASS:\n$output\n"
    else
        echo -e "\n- FAIL:\n$output\n"
        echo -e "No time synchronization daemons are installed."
        read -p "Would you like to apply remediation? (y/n): " apply_remediation

        if [[ "$apply_remediation" =~ ^[Yy]$ ]]; then
            echo "Choose one of the following time synchronization daemons:"
            echo "1. chrony"
            echo "2. systemd-timesyncd"
            echo "3. ntp"
            read -p "Enter the number corresponding to your choice: " choice
            
            case $choice in
                1)
                    echo "Installing chrony..."
                    apt install -y chrony
                    echo "Stopping and masking systemd-timesyncd..."
                    systemctl stop systemd-timesyncd.service
                    systemctl --now mask systemd-timesyncd.service
                    echo "Removing ntp package..."
                    apt purge -y ntp
                    echo "Remediation complete for chrony."
                    ;;
                2)
                    echo "Removing chrony package..."
                    apt purge -y chrony
                    echo "Removing ntp package..."
                    apt purge -y ntp
                    echo "Remediation complete for systemd-timesyncd."
                    ;;
                3)
                    echo "Installing ntp..."
                    apt install -y ntp
                    echo "Stopping and masking systemd-timesyncd..."
                    systemctl stop systemd-timesyncd.service
                    systemctl --now mask systemd-timesyncd.service
                    echo "Removing chrony package..."
                    apt purge -y chrony
                    echo "Remediation complete for ntp."
                    ;;
                *)
                    echo "Invalid choice. No remediation applied."
                    ;;
            esac
        else
            echo "No remediation applied."
        fi
    fi
}

