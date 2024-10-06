#!/bin/bash

# Function to check root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        zenity --error --text="This script must be run as root." --title="Permission Denied"
        exit 1
    fi
}

# Function to scan IP range
scan_ips() {
    local start_ip=$1
    local end_ip=$2
    local subnet_mask=$3
    local report="Scanning IPs from $start_ip to $end_ip with subnet mask $subnet_mask\n\n"

    # Convert IPs to decimal for easier comparison
    IFS=. read -r i1 i2 i3 i4 <<< "$start_ip"
    start_dec=$((i1 * 256**3 + i2 * 256**2 + i3 * 256 + i4))
    
    IFS=. read -r j1 j2 j3 j4 <<< "$end_ip"
    end_dec=$((j1 * 256**3 + j2 * 256**2 + j3 * 256 + j4))

    # Create a temporary file to store the scan results
    temp_report_file=$(mktemp)

    # Show a progress dialog
    ( 
        for ((ip_dec=start_dec; ip_dec<=end_dec; ip_dec++)); do
            # Convert decimal back to IP
            ip="$((ip_dec >> 24 & 255)).$((ip_dec >> 16 & 255)).$((ip_dec >> 8 & 255)).$((ip_dec & 255))"

            # Ping the IP and get details
            if ping -c 1 -W 1 "$ip" > /dev/null; then
                host_info=$(getent hosts "$ip")
                echo "IP: $ip - Reachable - Host Info: $host_info" >> "$temp_report_file"
            else
                echo "IP: $ip - Not Reachable" >> "$temp_report_file"
            fi

            # Update progress
            echo "Scanning IP: $ip"
            sleep 0.1  # Add a short delay to simulate progress
        done
    ) | zenity --progress --title="IP Scan" --text="Performing IP's Scan..." --percentage=0 --auto-close

    # Read the scan results
    report=$(<"$temp_report_file")
    rm "$temp_report_file"

    # Display results in a Zenity text info box
    zenity --info --text="$report" --title="IP Scan Results"
}

# Main function
main() {
    check_root
    start_ip=$(zenity --entry --title="IP Scanner" --text="Enter Starting IP Address:")
    end_ip=$(zenity --entry --title="IP Scanner" --text="Enter Ending IP Address:")
    subnet_mask=$(zenity --entry --title="IP Scanner" --text="Enter Subnet Mask (e.g. 255.255.255.0):")

    # Start scanning
    scan_ips "$start_ip" "$end_ip" "$subnet_mask"
}

# Run the main function
main
