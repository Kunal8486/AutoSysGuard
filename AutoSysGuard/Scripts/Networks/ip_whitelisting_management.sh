#!/bin/bash

# Specify the path for the whitelist file
WHITELIST_FILE="$HOME/whitelist.txt"

# Function to validate IP address format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -r i1 i2 i3 i4 <<< "$ip"
        # Ensure each octet is between 0-255
        if (( i1 >= 0 && i1 <= 255 && i2 >= 0 && i2 <= 255 && i3 >= 0 && i3 <= 255 && i4 >= 0 && i4 <= 255 )); then
            return 0
        fi
    fi
    return 1
}

# Function to gather user input for future IP whitelisting
get_future_ip() {
    future_ip=$(zenity --entry --title="Add Future IP" --text="Enter the future IP address you want to whitelist:")
    echo "$future_ip"
}

# Function to gather user input for local IP whitelisting
get_local_ip() {
    local_ip=$(zenity --entry --title="Add Local IP" --text="Enter the local IP address you want to whitelist:")
    echo "$local_ip"
}

# Function to set local network range from user input
set_local_network() {
    LOCAL_NETWORK=$(zenity --entry --title="Set Local Network" --text="Enter your local network range (e.g., 192.168.1.):")
    echo "$LOCAL_NETWORK"
}

# Function to add an IP address to the whitelist for future use
add_future_ip() {
    future_ip=$(get_future_ip)

    if validate_ip "$future_ip"; then
        if grep -q "$future_ip" "$WHITELIST_FILE"; then
            zenity --info --text="The IP address ($future_ip) is already whitelisted."
        else
            echo "$future_ip" >> "$WHITELIST_FILE"
            zenity --info --text="The IP address ($future_ip) has been added to the whitelist for future use."
        fi
    else
        zenity --error --text="Invalid IP address format. Please try again."
    fi
}

# Function to add an IP address to the whitelist from local network
add_local_ip() {
    local_ip=$(get_local_ip)

    if validate_ip "$local_ip"; then
        if [[ "$local_ip" == $LOCAL_NETWORK* ]]; then
            echo "$local_ip" >> "$WHITELIST_FILE"
            zenity --info --text="The local IP address ($local_ip) has been added to the whitelist."
        else
            zenity --error --text="The IP address ($local_ip) is not in the local network range ($LOCAL_NETWORK)."
        fi
    else
        zenity --error --text="Invalid IP address format. Please try again."
    fi
}

# Function to show current whitelisted IPs
show_whitelist() {
    if [ -s "$WHITELIST_FILE" ]; then
        zenity --text-info --title="Whitelisted IPs" --filename="$WHITELIST_FILE" --width=600 --height=400
    else
        zenity --info --text="No IP addresses are currently whitelisted."
    fi
}

# Set local network range at the start
set_local_network

# Main menu
while true; do
    action=$(zenity --list --title="IP Whitelisting Management" --column="Action" \
        "Add Future IP" \
        "Add Local IP" \
        "Show Whitelisted IPs" \
        "Exit")

    case $action in
        "Add Future IP")
            add_future_ip
            ;;
        "Add Local IP")
            add_local_ip
            ;;
        "Show Whitelisted IPs")
            show_whitelist
            ;;
        "Exit")
            break
            ;;
        *)
            zenity --error --text="Invalid option selected."
            ;;
    esac
done
