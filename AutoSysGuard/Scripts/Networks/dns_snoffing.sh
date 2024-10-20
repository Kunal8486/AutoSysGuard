#!/bin/bash

# Configuration file to store email alerts
CONFIG_FILE="$HOME/.dns_spoof_detector.conf"

# Define trusted DNS servers (modifiable via the GUI)
TRUSTED_DNS=("8.8.8.8" "1.1.1.1")

# Log file for DNS spoofing detection events
LOG_FILE="./log/dns_spoof.log"

# Default email for alerts (loaded from config or default)
DEFAULT_EMAIL="admin@example.com"
ALERT_EMAIL="$DEFAULT_EMAIL"

# Function to load configuration (email from config file)
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "ALERT_EMAIL=\"$DEFAULT_EMAIL\"" > "$CONFIG_FILE"
    fi
}

# Function to save email to config file
save_config() {
    echo "ALERT_EMAIL=\"$ALERT_EMAIL\"" > "$CONFIG_FILE"
}

# Function to detect DNS spoofing
detect_dns_spoofing() {
    INTERFACE=$(select_network_interface)
    
    if [[ -z "$INTERFACE" ]]; then
        whiptail --msgbox "No network interface selected. Exiting." 8 45
        exit 1
    fi
    
    whiptail --msgbox "Starting DNS Spoofing Detection on interface $INTERFACE..." 8 60

    sudo tcpdump -n -i "$INTERFACE" udp port 53 -l | while read line; do
        query_ip=$(echo "$line" | grep -oP '(?<=\bIP\b\s)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        response_ip=$(echo "$line" | grep -oP '(?<=\bA\b\s)[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        
        if [[ ! -z "$response_ip" ]]; then
            spoofed=true
            for dns in "${TRUSTED_DNS[@]}"; do
                if [[ "$response_ip" == "$dns" ]]; then
                    spoofed=false
                    break
                fi
            done
            
            if $spoofed; then
                whiptail --msgbox "Possible DNS Spoofing detected!\nQuery IP: $query_ip\nSpoofed IP: $response_ip" 10 60
                log_spoofing "$query_ip" "$response_ip"
                send_email_alert "$query_ip" "$response_ip"
            fi
        fi
    done
}

# Function to select network interface using Whiptail
select_network_interface() {
    # Get list of network interfaces (removing 'lo' loopback interface)
    INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo')
    
    if [[ -z "$INTERFACES" ]]; then
        whiptail --msgbox "No network interfaces found. Exiting." 8 45
        exit 1
    fi
    
    # Build options array for Whiptail
    OPTIONS=()
    for iface in $INTERFACES; do
        OPTIONS+=("$iface" "$iface")
    done

    # Use Whiptail to present the list of interfaces to the user
    INTERFACE=$(whiptail --title "Select Network Interface" --menu "Choose an interface to monitor:" 15 60 5 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

    echo "$INTERFACE"
}

# Function to log DNS spoofing events to file
log_spoofing() {
    local query_ip="$1"
    local response_ip="$2"
    echo "$(date): DNS Spoofing detected! Query IP: $query_ip, Spoofed IP: $response_ip" >> "$LOG_FILE"
    whiptail --msgbox "Event logged to $LOG_FILE" 8 45
}

# Function to send email alert
send_email_alert() {
    local query_ip="$1"
    local response_ip="$2"
    if [[ -n "$ALERT_EMAIL" ]]; then
        echo "DNS Spoofing detected!\nQuery IP: $query_ip\nSpoofed IP: $response_ip" | mail -s "DNS Spoofing Alert" "$ALERT_EMAIL"
        whiptail --msgbox "Alert sent to $ALERT_EMAIL" 8 45
    else
        whiptail --msgbox "Email alert is not configured." 8 45
    fi
}

# Function to manage trusted DNS servers
manage_trusted_dns() {
    local dns_list=$(whiptail --inputbox "Enter trusted DNS servers, separated by spaces:" 8 60 "${TRUSTED_DNS[*]}" 3>&1 1>&2 2>&3)
    
    if [[ -n "$dns_list" ]]; then
        TRUSTED_DNS=($dns_list)
        whiptail --msgbox "Trusted DNS servers updated:\n${TRUSTED_DNS[*]}" 10 60
    else
        whiptail --msgbox "No DNS servers entered. Retaining old list." 8 45
    fi
}

# Function to display logs
view_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        whiptail --textbox "$LOG_FILE" 15 60
    else
        whiptail --msgbox "No log file found at $LOG_FILE" 8 45
    fi
}

# Function to configure email alerts
configure_email_alert() {
    local email=$(whiptail --inputbox "Enter email for alerts:" 8 60 "$ALERT_EMAIL" 3>&1 1>&2 2>&3)
    
    if [[ -n "$email" ]]; then
        ALERT_EMAIL="$email"
        save_config  # Save the updated email to the config file
        whiptail --msgbox "Alert email updated to $ALERT_EMAIL" 8 45
    else
        whiptail --msgbox "No email entered. Retaining old email." 8 45
    fi
}

# Load configuration at the start
load_config

# Main Menu using Whiptail
while true; do
    action=$(whiptail --title "DNS Spoof Detector" --menu "Choose an action:" 15 60 6 \
        "1" "Start Detection" \
        "2" "Stop Detection" \
        "3" "Manage Trusted DNS" \
        "4" "View Logs" \
        "5" "Configure Email Alerts" \
        "6" "Exit" 3>&1 1>&2 2>&3)
    
    case $action in
        1)
            detect_dns_spoofing &
            DETECT_PID=$!
            ;;
        2)
            if [[ -n "$DETECT_PID" ]]; then
                kill "$DETECT_PID"
                whiptail --msgbox "DNS Spoofing Detection Stopped" 8 45
            else
                whiptail --msgbox "No detection is running" 8 45
            fi
            ;;
        3)
            manage_trusted_dns
            ;;
        4)
            view_logs
            ;;
        5)
            configure_email_alert
            ;;
        6)
            if [[ -n "$DETECT_PID" ]]; then
                kill "$DETECT_PID"
            fi
            break
            ;;
        *)
            whiptail --msgbox "Invalid option selected" 8 45
            ;;
    esac
done
