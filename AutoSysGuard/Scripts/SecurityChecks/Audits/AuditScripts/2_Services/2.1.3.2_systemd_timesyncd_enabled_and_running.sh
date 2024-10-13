#!/usr/bin/env bash

# Function to check the status of systemd-timesyncd service
check_timesyncd_status() {
    echo "Checking the status of systemd-timesyncd service..."

    # Check if the service exists
    if systemctl list-unit-files | grep -q 'systemd-timesyncd.service'; then
        # Get the enabled status
        ENABLED=$(systemctl is-enabled systemd-timesyncd.service 2>/dev/null)
        # Get the active status
        ACTIVE=$(systemctl is-active systemd-timesyncd.service 2>/dev/null)

        echo "Enabled: $ENABLED"
        echo "Active: $ACTIVE"

        if [[ "$ENABLED" == "enabled" && "$ACTIVE" == "active" ]]; then
            echo "Audit passed: systemd-timesyncd service is enabled and active."
            return 0  # Indicate success
        else
            echo "Audit failed: systemd-timesyncd service is not enabled or not active."
            return 1  # Indicate failure
        fi
    else
        echo "systemd-timesyncd.service does not exist on this system."
        return 2  # Indicate service does not exist
    fi
}

# Function for remediation
remediate() {
    echo "Applying remediation..."

    # Unmask the service if it's masked
    if [[ "$ENABLED" == "masked" ]]; then
        echo "Unmasking systemd-timesyncd.service..."
        sudo systemctl unmask systemd-timesyncd.service
    fi

    # Enable and start the systemd-timesyncd service
    echo "Enabling and starting systemd-timesyncd.service..."
    sudo systemctl --now enable systemd-timesyncd.service
    echo "Remediation applied: systemd-timesyncd service is now enabled and active."
}

# Function for masking the service if another time synchronization service is in use
mask_service() {
    echo "Stopping and masking systemd-timesyncd.service due to another time synchronization service in use..."
    sudo systemctl --now mask systemd-timesyncd.service
    echo "systemd-timesyncd.service has been masked."
}

# Main script execution
check_timesyncd_status
status=$?

if [[ $status -eq 0 ]]; then
    echo "systemd-timesyncd is properly configured."
elif [[ $status -eq 1 ]]; then
    # Prompt user for confirmation before applying remediation
    read -p "Do you want to apply remediation? (y/n): " choice
    case "$choice" in
        y|Y)
            remediate
            ;;
        n|N)
            echo "No remediation applied."
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    # Handle case where the service does not exist
    echo "You may need to install systemd-timesyncd."
    read -p "Do you want to install systemd-timesyncd? (y/n): " install_choice
    case "$install_choice" in
        y|Y)
            echo "Installing systemd-timesyncd..."
            sudo apt-get install systemd-timesyncd -y
            ;;
        n|N)
            echo "No installation applied."
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# After remediation, check if another time synchronization service is active
ACTIVE=$(systemctl is-active systemd-timesyncd.service 2>/dev/null)

if [[ "$ACTIVE" != "active" ]]; then
    read -p "Another time synchronization service is in use. Do you want to mask systemd-timesyncd.service? (y/n): " mask_choice
    case "$mask_choice" in
        y|Y)
            mask_service
            ;;
        n|N)
            echo "No masking applied."
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi
