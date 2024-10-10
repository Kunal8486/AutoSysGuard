#!/bin/bash

# Function to audit rsyslog FileCreateMode configuration
audit_rsyslog_file_create_mode() {
    echo "Auditing rsyslog FileCreateMode configuration..."

    # Check the FileCreateMode setting in rsyslog configuration
    file_create_mode=$(grep -E '^\$FileCreateMode' /etc/rsyslog.conf /etc/rsyslog.d/*.conf)

    if [[ -z "$file_create_mode" ]]; then
        echo "Audit: $FileCreateMode is not set in /etc/rsyslog.conf or /etc/rsyslog.d/*.conf."
        prompt_set_file_create_mode
    elif [[ "$file_create_mode" == *"0640"* ]]; then
        echo "Audit: $FileCreateMode is set to '0640'."
    else
        echo "Audit: $FileCreateMode is set to '$file_create_mode'."
        prompt_set_file_create_mode
    fi
}

# Function to prompt the user to set FileCreateMode
prompt_set_file_create_mode() {
    read -p "Do you want to set \$FileCreateMode to '0640' in rsyslog configuration? (y/n): " user_input

    if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
        set_file_create_mode
    else
        echo "You chose not to modify the FileCreateMode setting. Exiting."
    fi
}

# Function to set FileCreateMode in rsyslog configuration
set_file_create_mode() {
    echo "Setting \$FileCreateMode to '0640' in /etc/rsyslog.conf or a .conf file in /etc/rsyslog.d/..."

    # Check if the configuration file exists and modify it
    if grep -q '^\$FileCreateMode' /etc/rsyslog.conf; then
        # Update existing configuration
        sudo sed -i '/^\$FileCreateMode/c\$FileCreateMode 0640' /etc/rsyslog.conf
    else
        # Add the configuration if not present
        echo '$FileCreateMode 0640' | sudo tee -a /etc/rsyslog.conf > /dev/null
    fi

    # Restart the rsyslog service
    echo "Restarting rsyslog service..."
    sudo systemctl restart rsyslog

    if [ $? -eq 0 ]; then
        echo "Successfully restarted rsyslog service."
    else
        echo "Error: Failed to restart rsyslog service."
    fi
}

# Run the audit
audit_rsyslog_file_create_mode
