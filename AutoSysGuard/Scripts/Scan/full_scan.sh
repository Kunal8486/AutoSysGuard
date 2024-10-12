#!/bin/bash

# Constants
LOG_DIR="./log"
LOG_FILE="$LOG_DIR/full_scan.log"
SCAN_TOOL="clamscan"
PARALLEL_TOOL="parallel"
FRESHCLAM_LOG="$LOG_DIR/freshclam.log"
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
    if ! command -v "$SCAN_TOOL" &>/dev/null; then
        log_message "Error: $SCAN_TOOL is not installed. Attempting to install..."
        sudo apt-get install clamav -y >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Failed to install $SCAN_TOOL. Please install it manually."
            exit 1
        fi
        log_message "$SCAN_TOOL installation complete."
    fi

    if ! command -v "$PARALLEL_TOOL" &>/dev/null; then
        log_message "Error: $PARALLEL_TOOL is not installed. Attempting to install..."
        sudo apt-get install parallel -y >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Failed to install $PARALLEL_TOOL. Please install it manually."
            exit 1
        fi
        log_message "$PARALLEL_TOOL installation complete."
    fi
}

# Function to set up log file for ClamAV
setup_clamav_logging() {
    if [[ ! -f "$FRESHCLAM_LOG" ]]; then
        touch "$FRESHCLAM_LOG"
        sudo chown clamav:clamav "$FRESHCLAM_LOG"
        sudo chmod 640 "$FRESHCLAM_LOG"
        log_message "Created freshclam log file."
    fi
}

# Function to wait for freshclam to finish with timeout
wait_for_freshclam() {
    log_message "Checking if freshclam is running..."
    local wait_time=0

    while pgrep freshclam &>/dev/null; do
        if [ $wait_time -ge $MAX_WAIT_TIME ]; then
            log_message "Timeout reached. freshclam is still running after $MAX_WAIT_TIME seconds."
            echo "Timeout reached while waiting for freshclam. Please check its status."
            exit 1
        fi
        log_message "freshclam is running. Waiting for it to finish..."
        sleep 5
        wait_time=$((wait_time + 5))
    done
}

# Function to update virus definitions
update_definitions() {
    log_message "Updating ClamAV virus definitions..."
    if ! sudo freshclam >> "$FRESHCLAM_LOG" 2>&1; then
        log_message "Failed to update virus definitions."
        echo "Failed to update virus definitions. Check log for details."
        exit 1
    fi
    log_message "Virus definitions updated successfully."
}

# Function to scan the entire system
scan_system() {
    # Create a temporary file to hold all files to scan
    temp_file=$(mktemp)

    # Find all files and save them to the temporary file
    find / -type f 2>/dev/null > "$temp_file"
    total_files=$(wc -l < "$temp_file")
    scanned_files=0

    log_message "Starting full system scan..."
    echo "--------------------------------------------------"
    echo "          Full System Scan in Progress             "
    echo "--------------------------------------------------"
    echo "Total Files to Scan: $total_files"
    echo "Please wait while we perform the scan..."

    # Scan files in parallel using GNU Parallel
    cat "$temp_file" | $PARALLEL_TOOL --max-args 1 --jobs 4 --progress --bar "$SCAN_TOOL" --bell -i {} | while IFS= read -r line; do
        # Increment the scanned files counter if a file is scanned
        if [[ $line == Scanning* ]]; then
            scanned_files=$((scanned_files + 1))

            # Calculate progress percentage and estimated time remaining
            progress=$((scanned_files * 100 / total_files))
            elapsed_time=$((SECONDS))
            estimated_time=$((elapsed_time * total_files / scanned_files - elapsed_time))

            # Display progress
            printf "\rProgress: %d%% | Estimated Time Remaining: %02d:%02d" \
                "$progress" "$((estimated_time / 60))" "$((estimated_time % 60))"
        fi

        # Log the output line
        echo "$line" >> "$LOG_FILE"
    done

    # Final output
    echo -e "\n--------------------------------------------------"
    echo "                  Scan Completed                   "
    echo "--------------------------------------------------"
    echo "Check the log file for detailed results."

    # Check the exit status of clamscan
    if [ $? -eq 0 ]; then
        log_message "Full system scan completed successfully."
        echo "Scan completed successfully."
    else
        log_message "Full system scan encountered issues. Check the log for details."
        echo "Scan completed with errors. Please check the log for details."
    fi

    # Remove the temporary file
    rm "$temp_file"
}

# Main script execution
check_dependencies
setup_clamav_logging
wait_for_freshclam
update_definitions
scan_system
