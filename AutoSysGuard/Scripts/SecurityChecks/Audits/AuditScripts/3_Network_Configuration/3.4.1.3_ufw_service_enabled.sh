# 3.4.1.3 Ensure ufw service is enabled (Automated)
#!/bin/bash

# Function to check if UFW is enabled
check_ufw_enabled() {
    if systemctl is-enabled ufw.service &>/dev/null; then
        echo "UFW daemon is enabled."
    else
        echo "UFW daemon is not enabled."
        return 1
    fi
}

# Function to check if UFW is active
check_ufw_active() {
    if systemctl is-active ufw.service &>/dev/null; then
        echo "UFW daemon is active."
    else
        echo "UFW daemon is not active."
        return 1
    fi
}

# Function to check if UFW status is active
check_ufw_status() {
    if ufw status | grep -q "Status: active"; then
        echo "UFW is active."
    else
        echo "UFW is not active."
        return 1
    fi
}

# Check UFW daemon status
check_ufw_enabled
enabled_status=$?
check_ufw_active
active_status=$?
check_ufw_status
status_active=$?

# If any checks fail, prompt for remediation
if [[ $enabled_status -ne 0 || $active_status -ne 0 || $status_active -ne 0 ]]; then
    echo "One or more checks failed. You may need to apply remediation."
    read -p "Do you want to apply the remediation steps? (y/n): " choice

    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Unmasking the UFW daemon..."
        sudo systemctl unmask ufw.service
        
        echo "Enabling and starting the UFW daemon..."
        sudo systemctl --now enable ufw.service
        
        echo "Enabling UFW..."
        sudo ufw enable

        echo "UFW has been unmasked, enabled, and started."
    else
        echo "No action taken. Please ensure UFW is properly configured."
    fi
else
    echo "UFW is properly configured: enabled, active, and status is active."
fi
