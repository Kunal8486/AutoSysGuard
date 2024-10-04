#!/bin/bash

# AutoSysGuard Backup Script

# Set the username variable
username="kunal"

# Backup destination directory
backup_dest="./backup"

# Create backup directory if it doesn't exist
mkdir -p "$backup_dest"

# Important directories to backup (avoiding personal files)
backup_dirs=(
    "/etc"
    "/var/log"
    "/var/spool"
    "/root"
    "/boot"
)

# Timestamp for the backup file
timestamp=$(date +%Y-%m-%d_%H-%M-%S)
backup_file="important_backup_$timestamp.tar"

# Function to perform the backup
perform_backup() {
    tar --exclude="/home/$username/Desktop" \
        --exclude="/home/$username/Downloads" \
        --exclude="/home/$username/Documents" \
        --exclude="/home/$username/Music" \
        --exclude="/home/$username/Pictures" \
        --exclude="/home/$username/Videos" \
        -cvf "$backup_dest/$backup_file" "${backup_dirs[@]}"
}

# Function to check the backup status
check_backup_status() {
    if [ $? -eq 0 ]; then
        echo "Backup successfully created: $backup_dest/$backup_file"
    else
        echo "Backup creation failed."
    fi
}

# Main script execution
perform_backup
check_backup_status
