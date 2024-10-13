# 3.1.3 Ensure bluetooth is disabled (Automated)
#!/bin/bash

# Function to check Bluetooth service status
check_bluetooth_service() {
    echo "Checking Bluetooth service status..."

    # Check if the Bluetooth service is enabled
    enabled=$(systemctl is-enabled bluetooth.service | grep '^enabled')
    if [ -n "$enabled" ]; then
        echo "Bluetooth service is enabled."
        return 1  # Indicate failure
    fi

    # Check if the Bluetooth service is active
    active=$(systemctl is-active bluetooth.service | grep '^active')
    if [ -n "$active" ]; then
        echo "Bluetooth service is active."
        return 1  # Indicate failure
    fi

    echo "Bluetooth service is properly disabled."
    return 0  # Indicate success
}

# Function for remediation
remediate_bluetooth_service() {
    echo "Stopping and masking Bluetooth service..."
    systemctl stop bluetooth.service
    systemctl mask bluetooth.service
    echo "Bluetooth service stopped and masked."
    echo "Note: A reboot may be required to complete the remediation."
}

# Run the audit
check_bluetooth_service
status=$?

# If the audit fails, prompt for remediation
if [ $status -ne 0 ]; then
    read -p "Do you want to apply the remediation steps? (y/n): " choice
    if [[ "$choice" == [Yy] ]]; then
        remediate_bluetooth_service
    else
        echo "Remediation steps were not applied."
    fi
else
    echo "No remediation needed."
fi
