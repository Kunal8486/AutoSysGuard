#!/bin/bash

# Function to check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        zenity --error --text="This script must be run as root." --title="Permission Denied"
        exit 1
    fi
}

# Function to analyze SSL/TLS certificate for a given domain
analyze_ssl_tls() {
    domain=$1
    ssl_info=$(echo | openssl s_client -connect "$domain:443" -servername "$domain" 2>/dev/null | openssl x509 -text)
    
    if [ -z "$ssl_info" ]; then
        zenity --error --text="SSL/TLS certificate not found for $domain." --title="SSL/TLS Analysis"
        return
    fi

    # Extract key aspects
    subject=$(echo "$ssl_info" | grep 'Subject:' | sed 's/^.*Subject: //')
    issuer=$(echo "$ssl_info" | grep 'Issuer:' | sed 's/^.*Issuer: //')
    valid_from=$(echo "$ssl_info" | grep 'Not Before:' | sed 's/^.*Not Before: //')
    valid_to=$(echo "$ssl_info" | grep 'Not After :' | sed 's/^.*Not After : //')
    serial_number=$(echo "$ssl_info" | grep 'Serial Number:' | sed 's/^.*Serial Number: //')
    fingerprints=$(echo "$ssl_info" | grep -A1 'SHA256 Fingerprint' | tail -n1)

    # Display SSL/TLS certificate details
    zenity --info --text="SSL/TLS Certificate Analysis for $domain:\n\nSubject: $subject\nIssuer: $issuer\nValid From: $valid_from\nValid To: $valid_to\nSerial Number: $serial_number\nFingerprint: $fingerprints" --title="SSL/TLS Analysis"
}

# Function to prompt user for domain input
get_domains() {
    domain_input=$(zenity --entry --title="SSL/TLS Domain Input" --text="Enter domain names separated by commas:")
    if [ -n "$domain_input" ]; then
        IFS=',' read -r -a domains <<< "$domain_input"
        for domain in "${domains[@]}"; do
            analyze_ssl_tls "$(echo $domain | xargs)"  # Trim whitespace
        done
    else
        zenity --error --text="No domain names provided!" --title="Error"
    fi
}

# Main function to run the analysis
run_analysis() {
    check_root
    get_domains
    zenity --info --text="SSL/TLS Analysis Completed." --title="Analysis Complete"
}

# Start the analysis
run_analysis
