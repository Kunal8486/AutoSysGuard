#!/bin/bash

# Define log file
LOG_FILE="/var/log/bruteforce_detection.log"

# Define the threshold for failed attempts
THRESHOLD=5

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

# Function to find and display suspicious IPs
find_suspicious_ips() {
    log_message "Scanning for brute force attempts..."
    SUSPICIOUS_IPS=$(journalctl -u ssh.service --since "1 hour ago" | grep "Failed password" | grep -oP 'rhost=\K\S+' | sort | uniq -c | sort -nr | awk '$1 >= '$THRESHOLD' {print $2}')
    
    if [ -z "$SUSPICIOUS_IPS" ]; then
        zenity --info --text="No suspicious IPs detected with more than $THRESHOLD failed attempts."
        log_message "No brute force attempts detected."
    else
        echo "$SUSPICIOUS_IPS" > suspicious_ips.txt
        zenity --text-info --title="Suspicious IPs Detected" --filename=suspicious_ips.txt --width=400 --height=300
        log_message "Suspicious IPs detected: $(cat suspicious_ips.txt)"
    fi
}

# Function to block suspicious IPs
block_suspicious_ips() {
    if zenity --question --text="Do you want to block the suspicious IPs using the firewall?"; then
        while read -r IP; do
            ufw deny from $IP
            log_message "Blocked IP: $IP"
        done < suspicious_ips.txt
        zenity --info --text="All suspicious IPs have been blocked."
        log_message "All suspicious IPs blocked via firewall."
    fi
}

# Function to send alerts
send_alert() {
    EMAIL=$(zenity --entry --title="Alert Email" --text="Enter your email address for alerts:")
    if [ -z "$EMAIL" ]; then
        zenity --error --text="No email address entered. Skipping alerts."
        log_message "Alert email not set. Skipping email alerts."
    else
        zenity --info --text="Sending alert to $EMAIL."
        cat suspicious_ips.txt | mail -s "Brute Force Attack Detected" $EMAIL
        log_message "Alert sent to $EMAIL regarding brute force attacks."
    fi
}

# Function to apply fail2ban for automatic blocking
apply_fail2ban() {
    if zenity --question --text="Do you want to apply fail2ban for automated brute force protection?"; then
        if ! command -v fail2ban-client &> /dev/null; then
            zenity --info --text="Installing fail2ban..."
            apt-get install fail2ban -y
        fi

        systemctl enable fail2ban
        systemctl start fail2ban
        zenity --info --text="fail2ban is now configured and running."
        log_message "fail2ban installed and running for automated brute force protection."
    fi
}

# Main function
main() {
    check_zenity
    check_root
    find_suspicious_ips
    if [ -s suspicious_ips.txt ]; then
        block_suspicious_ips
        send_alert
    fi
    apply_fail2ban
}

# Run the main function
main
