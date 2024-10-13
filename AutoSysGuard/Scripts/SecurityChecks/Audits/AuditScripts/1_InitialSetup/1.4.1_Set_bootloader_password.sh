#!/bin/bash

# Define your username variable
read -p "Enter Username: " USERNAME  # Prompt for the username

# Function to check GRUB superuser settings
check_grub_superuser() {
    echo "Checking GRUB superuser settings..."
    # Check for the custom superuser configuration file
    SUPERUSER_LINE=$(grep "^set superusers" /etc/grub.d/99_custom_superuser)
    PASSWORD_LINE=$(grep "^password_pbkdf2" /etc/grub.d/99_custom_superuser)

    if [[ -z "$SUPERUSER_LINE" || -z "$PASSWORD_LINE" ]]; then
        echo "GRUB superuser settings are not configured correctly."
        echo "Superuser line: $SUPERUSER_LINE"
        echo "Password line: $PASSWORD_LINE"
        return 1  # Indicate that remediation is needed
    else
        echo "GRUB superuser settings are configured correctly."
        return 0  # No remediation needed
    fi
}

# Function to create an encrypted password
create_encrypted_password() {
    read -sp "Enter password: " PASSWORD  # Prompt for the password silently
    echo  # Move to the next line
    read -sp "Reenter password: " PASSWORD_CONFIRM  # Prompt for confirmation
    echo  # Move to the next line

    if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
        echo "Passwords do not match. Exiting."
        exit 1
    fi

    # Create the encrypted password using a heredoc
    ENCRYPTED_PASSWORD=$(grub-mkpasswd-pbkdf2 <<< "$PASSWORD" 2>&1)
    
    # Check if there was an error generating the password
    if [[ $? -ne 0 ]]; then
        echo "Error creating encrypted password: $ENCRYPTED_PASSWORD"
        exit 1
    fi

    echo "$ENCRYPTED_PASSWORD"  # Output the encrypted password
}

# Function to update GRUB configuration
update_grub_configuration() {
    echo "Updating GRUB configuration..."
    sudo update-grub
    echo "GRUB configuration updated."
}

# Function to add superuser settings
add_superuser_settings() {
    echo "Adding superuser settings to /etc/grub.d/99_custom_superuser..."
    
    # Get the encrypted password from the previous command output
    ENCRYPTED_PASSWORD=$(create_encrypted_password)

    # Create or overwrite the custom configuration file
    {
        echo "set superusers=\"$USERNAME\""
        echo "password_pbkdf2 $USERNAME $ENCRYPTED_PASSWORD"
    } | sudo tee /etc/grub.d/99_custom_superuser > /dev/null

    # Set permissions for the custom configuration file
    sudo chown root:root /etc/grub.d/99_custom_superuser
    sudo chmod 0644 /etc/grub.d/99_custom_superuser

    echo "Superuser settings added."
}

# Main script execution
check_grub_superuser
if [[ $? -ne 0 ]]; then
    read -p "Would you like to apply remediation? (y/n): " response
    if [[ "$response" == "y" ]]; then
        add_superuser_settings
        update_grub_configuration
    else
        echo "Remediation not applied. Exiting."
        exit 1
    fi
else
    echo "No remediation needed. Exiting."
    exit 0
fi
