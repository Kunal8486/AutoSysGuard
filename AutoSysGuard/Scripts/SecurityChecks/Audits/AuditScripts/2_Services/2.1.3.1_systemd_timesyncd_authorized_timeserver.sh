#!/usr/bin/env bash

# Variables
l_ntp_ts="time.nist.gov"
l_ntp_fb="time-a-g.nist.gov time-b-g.nist.gov time-c-g.nist.gov"
l_conf_file="/etc/systemd/timesyncd.conf"

# Function to check if systemd-timesyncd is configured correctly
check_timesyncd() {
    echo "Checking /etc/systemd/timesyncd.conf for NTP settings..."
    
    # Check for NTP setting
    NTP_OUTPUT=$(grep -Ph '^\h*NTP=\H+' "$l_conf_file")
    FallbackNTP_OUTPUT=$(grep -Ph '^\h*FallbackNTP=\H+' "$l_conf_file")
    
    # Check if NTP is configured correctly
    if [[ -z "$NTP_OUTPUT" ]]; then
        echo "Audit failed: NTP is not configured."
        return 1  # Indicate failure
    else
        echo "Audit passed: $NTP_OUTPUT"
    fi
    
    # Check if FallbackNTP is configured correctly
    if [[ -z "$FallbackNTP_OUTPUT" ]]; then
        echo "Audit failed: FallbackNTP is not configured."
        return 1  # Indicate failure
    else
        echo "Audit passed: $FallbackNTP_OUTPUT"
    fi
    
    return 0  # Indicate success
}

# Function for remediation
remediate() {
    echo "Applying remediation..."
    
    # Check and add NTP entry if missing
    if ! grep -Ph '^\h*NTP=\H+' "$l_conf_file"; then
        if ! grep -Pqs '^\h*\[Time\]' "$l_conf_file"; then
            echo "[Time]" | sudo tee -a "$l_conf_file" > /dev/null
        fi
        echo "NTP=$l_ntp_ts" | sudo tee -a "$l_conf_file" > /dev/null
        echo "Added NTP=$l_ntp_ts to $l_conf_file"
    else
        echo "NTP is already configured."
    fi

    # Check and add FallbackNTP entry if missing
    if ! grep -Ph '^\h*FallbackNTP=\H+' "$l_conf_file"; then
        if ! grep -Pqs '^\h*\[Time\]' "$l_conf_file"; then
            echo "[Time]" | sudo tee -a "$l_conf_file" > /dev/null
        fi
        echo "FallbackNTP=$l_ntp_fb" | sudo tee -a "$l_conf_file" > /dev/null
        echo "Added FallbackNTP=$l_ntp_fb to $l_conf_file"
    else
        echo "FallbackNTP is already configured."
    fi

    # Reload systemd-timesyncd configuration
    echo "Reloading systemd-timesyncd configuration..."
    sudo systemctl try-reload-or-restart systemd-timesyncd
    echo "Remediation applied."
}

# Main script execution
if check_timesyncd; then
    echo "Systemd-timesyncd is configured correctly."
else
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
fi
