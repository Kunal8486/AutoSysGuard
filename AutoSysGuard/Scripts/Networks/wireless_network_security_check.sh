#!/bin/bash

# Check for required tools and install if necessary
check_dependencies() {
    for cmd in nmcli iwlist aircrack-ng; do
        if ! command -v $cmd &> /dev/null; then
            zenity --question --text="$cmd is not installed. Would you like to install it now?"
            if [[ $? -eq 0 ]]; then
                sudo apt-get install -y $cmd
            else
                zenity --error --text="Dependency $cmd is required. Exiting."
                exit 1
            fi
        fi
    done
}

# Function to display available wireless networks and security protocols
list_wireless_networks() {
    zenity --info --title="Scanning for Wireless Networks" --text="Please wait while we scan for wireless networks..."
    networks=$(nmcli -f SSID,SECURITY,SIGNAL device wifi list | awk 'NR>1 {print $1, $2, $3}')
    
    # Format the output into a Zenity list window with appropriate size
    zenity --list --title="Available Wireless Networks" --width=400 --height=500 \
           --column="SSID" --column="Security" --column="Signal Strength" \
           $(nmcli -f SSID,SECURITY,SIGNAL device wifi list | awk 'NR>1 {print $1, $2, $3}') 
}


# Check for hidden SSIDs
check_hidden_ssids() {
    hidden=$(nmcli -f SSID,SECURITY device wifi list | grep -- "^\s" | awk '{print $1}')
    if [ -z "$hidden" ]; then
        zenity --info --title="Hidden SSID Check" --text="No hidden SSIDs found."
    else
        zenity --warning --title="Hidden SSID Detected" --text="Hidden SSID detected: $hidden"
    fi
}

# Function to check rogue access points
check_rogue_aps() {
    # Use aircrack-ng for detecting rogue APs
    zenity --info --title="Rogue AP Detection" --text="Checking for rogue access points..."
    rogue_aps=$(airmon-ng | grep 'Rogue' | awk '{print $2}')
    
    if [ -z "$rogue_aps" ]; then
        zenity --info --title="Rogue AP Detection" --text="No rogue access points found."
    else
        zenity --warning --title="Rogue APs Detected" --text="Rogue access points found: $rogue_aps"
    fi
}

# Function to check encryption strength
check_encryption_strength() {
    zenity --info --title="Encryption Check" --text="Checking encryption strength of Wi-Fi networks..."
    encryption=$(nmcli -f SSID,SECURITY device wifi list | grep -E 'WPA2|WPA3' | awk '{print $1, $2}')
    
    if [ -z "$encryption" ]; then
        zenity --warning --title="Weak Encryption Detected" --text="Networks with weak encryption found. Consider upgrading to WPA2/WPA3."
    else
        zenity --info --title="Encryption Strength" --text="Secure Wi-Fi networks with WPA2/WPA3: $encryption"
    fi
}

# Check for interference from other channels
check_channel_interference() {
    zenity --info --title="Channel Interference" --text="Analyzing channel interference..."
    channels=$(iwlist wlan0 channel | grep -E 'Channel [0-9]{1,2} : [0-9]{1,3}' | awk '{print $2, $5}')
    
    if [ -z "$channels" ]; then
        zenity --info --title="Channel Interference" --text="No channel interference detected."
    else
        zenity --warning --title="Channel Interference" --text="Channel interference found: $channels"
    fi
}

# Function to show connected devices
show_connected_devices() {
    zenity --info --title="Connected Devices" --text="Displaying devices connected to the Wi-Fi network..."
    connected_devices=$(arp -a | grep -v 'incomplete')
    
    if [ -z "$connected_devices" ]; then
        zenity --info --title="No Devices Connected" --text="No devices are currently connected."
    else
        zenity --list --title="Connected Devices" --column="IP Address" --column="MAC Address" --width=500 --height=300 --text="$connected_devices"
    fi
}

# Main menu
main_menu() {
    choice=$(zenity --list --title="Wireless Network Security Check" --width=500 --height=300 --radiolist --column="Select" --column="Task" \
        TRUE "List Wireless Networks" \
        FALSE "Check Hidden SSIDs" \
        FALSE "Check Rogue Access Points" \
        FALSE "Check Encryption Strength" \
        FALSE "Check Channel Interference" \
        FALSE "Show Connected Devices" \
        --text="Choose a wireless network security task:")
    
    case $choice in
        "List Wireless Networks")
            list_wireless_networks
            ;;
        "Check Hidden SSIDs")
            check_hidden_ssids
            ;;
        "Check Rogue Access Points")
            check_rogue_aps
            ;;
        "Check Encryption Strength")
            check_encryption_strength
            ;;
        "Check Channel Interference")
            check_channel_interference
            ;;
        "Show Connected Devices")
            show_connected_devices
            ;;
        *)
            zenity --error --text="Invalid selection."
            ;;
    esac
}

# Run dependency check before executing the script
check_dependencies

# Show the main menu
main_menu
