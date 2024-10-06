#!/bin/bash

# Define log file for intrusion detection
LOG_FILE="/var/log/intrusion_detection.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Function to check if necessary packages are installed
check_packages() {
    if ! command -v snort &> /dev/null; then
        zenity --error --text="Snort is not installed. Please install it using:\nsudo apt-get install snort"
        log_message "Snort not installed. Exiting."
        exit 1
    fi

    if ! command -v fail2ban-client &> /dev/null; then
        zenity --error --text="Fail2Ban is not installed. Please install it using:\nsudo apt-get install fail2ban"
        log_message "Fail2Ban not installed. Exiting."
        exit 1
    fi
}

# Function to run Snort for intrusion detection
run_snort() {
    log_message "Running Snort for intrusion detection..."

    # Run snort in the background, monitor the network interface
    snort -A console -i eth0 -c /etc/snort/snort.conf -l /var/log/snort/ &
    SNORT_PID=$!

    zenity --info --text="Snort is running in the background for intrusion detection. PID: $SNORT_PID"

    # Wait for a while (or implement a proper control mechanism)
    sleep 10

    # Stop snort
    kill $SNORT_PID
    log_message "Snort stopped."
}

# Function to analyze logs and detect potential intrusions
analyze_logs() {
    log_message "Analyzing logs for potential intrusions..."

    # Example check for failed SSH attempts
    SUSPICIOUS_ATTEMPTS=$(journalctl -u ssh.service --since "1 hour ago" | grep "Failed password" | wc -l)

    if [ "$SUSPICIOUS_ATTEMPTS" -gt 0 ]; then
        zenity --info --text="Detected $SUSPICIOUS_ATTEMPTS suspicious SSH login attempts!"
        log_message "$SUSPICIOUS_ATTEMPTS suspicious SSH login attempts detected."
    else
        zenity --info --text="No suspicious activities detected in the last hour."
        log_message "No suspicious activities detected."
    fi
}

# Function to block suspicious IPs
block_suspicious_ips() {
    if zenity --question --text="Do you want to block suspicious IPs detected in logs?"; then
        SUSPICIOUS_IPS=$(journalctl -u ssh.service --since "1 hour ago" | grep "Failed password" | grep -oP 'rhost=\K\S+' | sort | uniq)

        if [ -z "$SUSPICIOUS_IPS" ]; then
            zenity --info --text="No suspicious IPs found to block."
            log_message "No suspicious IPs found."
            return
        fi

        echo "$SUSPICIOUS_IPS" | while read -r IP; do
            ufw deny from $IP
            log_message "Blocked IP: $IP"
        done

        zenity --info --text="All suspicious IPs have been blocked."
        log_message "All suspicious IPs blocked via firewall."
    fi
}

# Main function
main() {
    check_packages
    run_snort
    analyze_logs
    block_suspicious_ips
}

# Run the main function
main
