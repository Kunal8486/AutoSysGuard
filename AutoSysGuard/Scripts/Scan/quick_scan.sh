#!/bin/bash

# Constants
LOG_DIR="./log"
LOG_FILE="$LOG_DIR/quick_scan.log"
RKHUNTER_TOOL="rkhunter"
MAX_WAIT_TIME=300  # Maximum wait time in seconds

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to log messages
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOG_FILE"
}

# Function to check for dependencies
check_dependencies() {
    if ! command -v "$RKHUNTER_TOOL" &>/dev/null; then
        log_message "Error: $RKHUNTER_TOOL is not installed. Attempting to install..."
        sudo apt-get install rkhunter -y >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Failed to install $RKHUNTER_TOOL. Please install it manually."
            exit 1
        fi
        log_message "$RKHUNTER_TOOL installation complete."
    fi
}

# Function to update RKHunter's definitions
update_definitions() {
    log_message "Updating RKHunter definitions..."
    sudo rkhunter --update >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
        log_message "Warning: Failed to update RKHunter definitions. Continuing with the scan..."
        echo "Warning: Failed to update definitions. Continuing with the scan. Check log for details."
    else
        log_message "RKHunter definitions updated successfully."
    fi
}

# Function to scan specified directories
scan_files() {
    log_message "Starting quick scan..."
    echo "--------------------------------------------------"
    echo "           Quick Scan in Progress        "
    echo "--------------------------------------------------"

    # Run RKHunter scan without specifying directories, as it will scan the entire system based on configuration
    sudo rkhunter --check >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
        log_message "Scan completed without issues."
        echo "Scan completed without issues."
    else
        log_message "Scan encountered issues. Check the log for details."
        echo "Scan encountered issues. Please check the log for details."
    fi

    echo -e "\n--------------------------------------------------"
    echo "                  Scan Completed                   "
    echo "--------------------------------------------------"
    echo "Check the log file for detailed results."
}

# Main script execution
check_dependencies
update_definitions
scan_files
