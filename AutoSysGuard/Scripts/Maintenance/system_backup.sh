#!/bin/bash

# Define username
USERNAME="kunal"  # Replace with your actual username

# Backup destination
BACKUP_DIR="./"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

# Directories to back up
DIRS_TO_BACKUP=(
    "/home/$USERNAME"                # User data
    "/etc"                           # System configuration
    "/var/lib/dpkg"                 # Installed packages info
    "/var/cache/apt/archives"        # Cached package files
    "/var/www"                       # Web server files (if applicable)
    "/var/lib/mysql"                 # MySQL database files (if applicable)
    "/var/lib/postgresql"            # PostgreSQL database files (if applicable)
    "/var/mail"                      # Mail storage (if applicable)
    "/var/log"                       # Log files
   
)

# Create the backup
tar -czf "$BACKUP_FILE" "${DIRS_TO_BACKUP[@]}"

# Optional: Remove backups older than 7 days
find "$BACKUP_DIR" -type f -name 'backup_*.tar.gz' -mtime +7 -exec rm {} \;

echo "Backup created at $BACKUP_FILE"
