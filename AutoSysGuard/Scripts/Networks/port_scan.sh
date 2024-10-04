#!/bin/bash

# Function to check if nmap is installed
check_nmap() {
    if ! command -v nmap &> /dev/null; then
        zenity --error --text="nmap is not installed. Please install it using: sudo apt-get install nmap"
        exit 1
    fi
}

# Function to prompt for scan parameters
get_scan_details() {
    IP=$(zenity --entry --title="Port Scan" --text="Enter the IP address to scan:" --entry-text="192.168.1.1")
    if [[ -z "$IP" ]]; then
        zenity --error --text="No IP address provided. Exiting."
        exit 1
    fi

    PORT_RANGE=$(zenity --entry --title="Port Scan" --text="Enter the port range to scan (e.g., 1-1000):" --entry-text="1-1000")
    if [[ -z "$PORT_RANGE" ]]; then
        zenity --error --text="No port range provided. Exiting."
        exit 1
    fi

    SCAN_TYPE=$(zenity --list --title="Select Scan Type" --text="Choose the type of scan:" \
        --column="Scan Type" "SYN Scan" "TCP Connect Scan" "UDP Scan" --height=300 --width=400)

    if [[ -z "$SCAN_TYPE" ]]; then
        zenity --error --text="No scan type selected. Exiting."
        exit 1
    fi

    VERSION_DETECTION=$(zenity --question --text="Enable service version detection?" --title="Service Version Detection")
    if [[ $? -eq 0 ]]; then
        VERSION_FLAG="-sV"
    else
        VERSION_FLAG=""
    fi
}

# Function to perform the port scan
perform_port_scan() {
    local ip=$1
    local port_range=$2
    local scan_type=$3
    local version_flag=$4

    case $scan_type in
        "SYN Scan")
            SCAN_FLAG="-sS"
            ;;
        "TCP Connect Scan")
            SCAN_FLAG="-sT"
            ;;
        "UDP Scan")
            SCAN_FLAG="-sU"
            ;;
        *)
            zenity --error --text="Invalid scan type selected. Exiting."
            exit 1
            ;;
    esac

    OUTPUT=$(nmap $SCAN_FLAG $version_flag -p "$port_range" "$ip" -oG - | grep '/open' | awk '{print $2, $3}')

    if [[ -z "$OUTPUT" ]]; then
        zenity --info --text="No open ports found for IP $ip in range $port_range."
    else
        echo "$OUTPUT" > scan_results.txt
        zenity --text-info --title="Port Scan Results" --filename=scan_results.txt --width=600 --height=400
    fi
}

# Main function
main() {
    check_nmap
    get_scan_details
    perform_port_scan "$IP" "$PORT_RANGE" "$SCAN_TYPE" "$VERSION_FLAG"
}

# Run the main function
main
