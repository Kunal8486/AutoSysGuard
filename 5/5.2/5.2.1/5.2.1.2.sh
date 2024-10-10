#!/bin/bash

# Check if auditd is enabled
auditd_enabled=$(systemctl is-enabled auditd 2>/dev/null)

if [ "$auditd_enabled" == "enabled" ]; then
    echo "Auditd is already enabled."
else
    echo "Auditd is not enabled."
    read -p "Do you want to enable auditd? (y/n): " enable_choice
    if [[ "$enable_choice" == "y" || "$enable_choice" == "Y" ]]; then
        systemctl --now enable auditd
        echo "Auditd has been enabled."
    else
        echo "Auditd will not be enabled."
    fi
fi

# Check if auditd is active
auditd_active=$(systemctl is-active auditd 2>/dev/null)

if [ "$auditd_active" == "active" ]; then
    echo "Auditd is already active."
else
    echo "Auditd is not active."
    read -p "Do you want to start auditd? (y/n): " start_choice
    if [[ "$start_choice" == "y" || "$start_choice" == "Y" ]]; then
        systemctl start auditd
        echo "Auditd has been started."
    else
        echo "Auditd will not be started."
    fi
fi
