# 2.2.10 Ensure IMAP and POP3 server are not installed (Automated)
#!/bin/bash

# Function to check if dovecot-imapd and dovecot-pop3d are installed
check_dovecot_installed() {
    dpkg -l | grep -q "^ii\s*dovecot-imapd" || dpkg -l | grep -q "^ii\s*dovecot-pop3d"
}

# Function to prompt the user for confirmation
prompt_user() {
    read -p "dovecot-imapd and dovecot-pop3d are currently installed. Do you want to remove them? (y/n): " choice
    case "$choice" in
        y|Y ) remove_dovecot;;
        n|N ) echo "dovecot removal cancelled."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n."; prompt_user;;
    esac
}

# Function to remove dovecot-imapd and dovecot-pop3d
remove_dovecot() {
    echo "Removing dovecot-imapd and dovecot-pop3d..."
    sudo apt purge -y dovecot-imapd dovecot-pop3d
    if [[ $? -eq 0 ]]; then
        echo "dovecot-imapd and dovecot-pop3d have been successfully removed."
    else
        echo "Failed to remove dovecot packages. Please check your permissions or package manager."
    fi
}

# Main script execution
if check_dovecot_installed; then
    echo "dovecot-imapd and dovecot-pop3d are currently installed."
    prompt_user
else
    echo "dovecot-imapd and dovecot-pop3d are not installed."
fi

# Diagnostic check for installed packages
echo "Checking installed packages for dovecot-imapd and dovecot-pop3d:"
dpkg -l | grep dovecot || echo "No dovecot packages found."
