#!/usr/bin/env bash

# Function to check if the kernel parameter is set correctly
check_kernel_parameter() {
    local kp_name="$1"
    local expected_value="$2"

    # Check the current running configuration
    local current_value
    current_value=$(sysctl "$kp_name" | awk -F= '{print $2}' | xargs)

    if [ "$current_value" == "$expected_value" ]; then
        echo " - \"$kp_name\" is correctly set to \"$current_value\" in the running configuration."
    else
        echo " - \"$kp_name\" is incorrectly set to \"$current_value\" in the running configuration and should be \"$expected_value\"."
    fi

    # Check the configuration files
    local config_files
    config_files=$(grep -l "^$kp_name" /etc/sysctl.conf /etc/sysctl.d/*.conf 2>/dev/null)

    if [ -z "$config_files" ]; then
        echo " - \"$kp_name\" is not set in any configuration file."
    else
        while IFS= read -r file; do
            local file_value
            file_value=$(grep "^$kp_name" "$file" | awk -F= '{print $2}' | xargs)
            if [ "$file_value" == "$expected_value" ]; then
                echo " - \"$kp_name\" is correctly set to \"$file_value\" in \"$file\"."
            else
                echo " - \"$kp_name\" is incorrectly set to \"$file_value\" in \"$file\" and should be \"$expected_value\"."
            fi
        done <<< "$config_files"
    fi
}

# Parameters to check
kernel_param="kernel.randomize_va_space"
expected_value="2"

# Run the check
echo "Checking kernel parameter \"$kernel_param\"..."
check_kernel_parameter "$kernel_param" "$expected_value"

# Ask user if they want to apply remediation only if necessary
if sysctl -n "$kernel_param" | grep -qv "$expected_value"; then
    read -p "Do you want to set \"$kernel_param\" to \"$expected_value\"? (y/n): " answer
else
    echo "No changes needed, \"$kernel_param\" is already set to \"$expected_value\"."
    exit 0
fi

if [[ "$answer" == "y" ]]; then
    # Update the configuration
    echo "Setting $kernel_param to $expected_value..."

    # Check if the config file already exists
    config_file="/etc/sysctl.d/60-kernel_sysctl.conf"
    
    # Create or update the config file
    if [ -f "$config_file" ]; then
        # Remove existing entry
        sed -i "/^$kernel_param/d" "$config_file"
    fi
    
    # Add the new setting
    echo "$kernel_param = $expected_value" >> "$config_file"

    # Apply the changes
    sysctl -w "$kernel_param=$expected_value"

    echo "Remediation applied: $kernel_param has been set to $expected_value."
else
    echo "No changes made."
fi
