#!/bin/bash

# Define log file
LOG_FILE="/var/log/ssh_hardening.log"
ALLOWED_USERS_FILE="/etc/ssh/allowed_users.txt"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to check if Zenity is installed
check_zenity() {
    if ! command -v zenity &> /dev/null; then
        zenity --error --text="Zenity is not installed. Please install it using:\nsudo apt-get install zenity"
        log_message "Zenity not installed. Exiting."
        exit 1
    fi
}

# Function to check if the user is root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        zenity --error --text="This script must be run as root. Please run it with 'sudo'."
        log_message "Script run without root privileges. Exiting."
        exit 1
    fi
}

# Function to display current SSH configuration
display_current_ssh_config() {
    CURRENT_CONFIG=$(cat /etc/ssh/sshd_config)
    echo "$CURRENT_CONFIG" > current_ssh_config.txt
    zenity --text-info --title="Current SSH Configuration" --filename=current_ssh_config.txt --width=600 --height=400
}

# Function to manage allowed users
manage_users() {
    touch $ALLOWED_USERS_FILE

    if zenity --question --text="Do you want to manage allowed users for SSH access?"; then
        USERS=$(< $ALLOWED_USERS_FILE)
        USERNAME=$(zenity --entry --title="Manage Allowed Users" --text="Enter usernames separated by commas (e.g. user1,user2):" --entry-text="$USERS")
        echo "$USERNAME" | tr ',' '\n' | sort | uniq > $ALLOWED_USERS_FILE
        zenity --info --text="Allowed users have been updated."
        log_message "Allowed users updated: $(cat $ALLOWED_USERS_FILE)"
    fi

    if zenity --question --text="Do you want to view allowed users?"; then
        zenity --text-info --title="Allowed Users" --filename=$ALLOWED_USERS_FILE --width=300 --height=200
    fi
}

# Function to track failed login attempts
track_failed_logins() {
    if zenity --question --text="Do you want to track failed login attempts?"; then
        AUTH_LOG="/var/log/auth.log"
        FAILED_LOGINS=$(grep "Failed password" $AUTH_LOG | tail -n 10)
        echo "$FAILED_LOGINS" > failed_logins.txt
        zenity --text-info --title="Failed Login Attempts" --filename=failed_logins.txt --width=600 --height=400
    fi
}

# Function to harden SSH configuration
harden_ssh() {
    # Back up the current SSH configuration
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    log_message "Backup of sshd_config created."

    # Disable root login
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    log_message "Root login disabled."

    # Disable password authentication
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    log_message "Password authentication disabled."

    # Change the default SSH port
    PORT=$(zenity --entry --title="Change SSH Port" --text="Enter a new SSH port (default is 22):" --entry-text="22")
    if [[ ! -z "$PORT" && "$PORT" != "22" ]]; then
        if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
            zenity --error --text="Invalid port number. Please enter a number between 1 and 65535."
            log_message "Invalid port entered: $PORT."
            exit 1
        fi
        sed -i "s/^Port .*/Port $PORT/" /etc/ssh/sshd_config
        log_message "SSH port changed to $PORT."
    fi

    # Restart the SSH service
    if systemctl restart sshd; then
        zenity --info --text="SSH hardening completed successfully.\n\nChanges made:\n- Root login disabled\n- Password authentication disabled\n- SSH port changed to $PORT"
        log_message "SSH service restarted successfully."
    else
        zenity --error --text="Failed to restart SSH service. Please check the logs."
        log_message "Failed to restart SSH service."
    fi
}

# Function for SSH key management
manage_keys() {
    if zenity --question --text="Do you want to generate SSH keys for user authentication?"; then
        USERNAME=$(zenity --entry --title="SSH Key Generation" --text="Enter your username:")
        ssh-keygen -t rsa -b 2048 -f /home/$USERNAME/.ssh/id_rsa -N "" < /dev/null
        zenity --info --text="SSH key generated at /home/$USERNAME/.ssh/id_rsa."
        log_message "SSH keys generated for user $USERNAME."
    fi
}

# Function to apply firewall rules
apply_firewall_rules() {
    if zenity --question --text="Do you want to apply firewall rules for SSH?"; then
        zenity --info --text="Applying firewall rules to allow access only from specified IP addresses."
        # Example of allowing SSH from specific IP
        while true; do
            IP_ADDRESS=$(zenity --entry --title="Firewall Rule" --text="Enter an IP address to allow access (leave blank to finish):")
            if [[ -z "$IP_ADDRESS" ]]; then
                break
            fi
            ufw allow from $IP_ADDRESS to any port $PORT
            log_message "Firewall rule added: allow from $IP_ADDRESS to port $PORT."
        done
    fi
}

# Main function
main() {
    check_zenity
    check_root
    display_current_ssh_config
    manage_users
    track_failed_logins
    if zenity --question --text="Do you want to proceed with SSH hardening?"; then
        harden_ssh
        manage_keys
        apply_firewall_rules
    else
        zenity --info --text="SSH hardening canceled by user."
        log_message "SSH hardening canceled by user."
    fi
}

# Run the main function
main
