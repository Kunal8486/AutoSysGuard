#!/bin/bash

# Define log directory and log file
LOG_DIR="./log"
LOG_FILE="$LOG_DIR/basic_linux_security_scan.log"

# Check if log directory exists, if not create it
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
fi

# Function to check if a tool is installed, if not install it
check_and_install() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 is not installed. Installing..."
        sudo apt-get update
        sudo apt-get install -y $1
    else
        echo "$1 is already installed."
    fi
}

# Function to run a command and log output
run_and_log() {
    echo "### $1 ###" | tee -a "$LOG_FILE"
    eval $2 | tee -a "$LOG_FILE"
    echo -e "\n" | tee -a "$LOG_FILE"
}

# Check and install necessary tools
check_and_install "rkhunter"
check_and_install "chkrootkit"
check_and_install "ufw"
check_and_install "unattended-upgrades"

echo "Starting basic Linux security scan..." | tee "$LOG_FILE"

# 1. Run rootkit check with rkhunter
run_and_log "Rootkit Scan with rkhunter" "sudo rkhunter --check --rwo"

# 2. Run rootkit check with chkrootkit
run_and_log "Rootkit Scan with chkrootkit" "sudo chkrootkit"

# 3. Check for open network ports
run_and_log "Open Ports Scan" "sudo netstat -tuln"

# 4. Find SUID/SGID files (potential privilege escalation issues)
run_and_log "SUID/SGID Files" "find / -type f \( -perm -4000 -o -perm -2000 \) -exec ls -ld {} \;"

# 5. Check firewall status (UFW)
run_and_log "Firewall Status (UFW)" "sudo ufw status"

# 6. Check for automatic security updates
run_and_log "Unattended Upgrades Status" "sudo unattended-upgrades --dry-run"

# 7. Check for world-writable files (which could be exploited)
run_and_log "World-writable Files" "find / -xdev -type f -perm -0002"

# 8. Check for files owned by no user or no group (misconfigurations)
run_and_log "Files with No Owner or No Group" "find / -nouser -o -nogroup"

echo "Basic Linux security scan completed. Results saved in $LOG_FILE"
