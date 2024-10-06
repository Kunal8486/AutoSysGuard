#!/bin/bash

# File to store the MAC address list
WHITELIST_FILE="./mac_whitelist.txt"
BLACKLIST_FILE="./mac_blacklist.txt"

# Create files if they don't exist
touch "$WHITELIST_FILE" "$BLACKLIST_FILE"

# Function to display the main menu
show_menu() {
    ACTION=$(zenity --list --title="MAC Address Filtering" \
    --column="Action" \
    "Add MAC Address to Whitelist" \
    "Remove MAC Address from Whitelist" \
    "Add MAC Address to Blacklist" \
    "Remove MAC Address from Blacklist" \
    "View Whitelist" \
    "View Blacklist" \
    "Exit")

    case $ACTION in
        "Add MAC Address to Whitelist") add_mac_address "$WHITELIST_FILE" ;;
        "Remove MAC Address from Whitelist") remove_mac_address "$WHITELIST_FILE" ;;
        "Add MAC Address to Blacklist") add_mac_address "$BLACKLIST_FILE" ;;
        "Remove MAC Address from Blacklist") remove_mac_address "$BLACKLIST_FILE" ;;
        "View Whitelist") view_mac_addresses "$WHITELIST_FILE" ;;
        "View Blacklist") view_mac_addresses "$BLACKLIST_FILE" ;;
        "Exit") exit 0 ;;
        *) zenity --error --text="Invalid selection. Please try again." ;;
    esac
}

# Function to validate MAC address format
validate_mac() {
    local mac=$1
    if [[ $mac =~ ^([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to prompt the user for a MAC address with examples
prompt_mac_address() {
    zenity --info --text="Please enter a MAC address in the format XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX.\n\nExample:\n01:23:45:67:89:AB\nor\n01-23-45-67-89-AB"
    MAC=$(zenity --entry --title="Enter MAC Address" --text="Enter MAC address:")
    echo "$MAC"
}

# Function to add MAC address
add_mac_address() {
    local file=$1
    MAC=$(prompt_mac_address)
    
    if validate_mac "$MAC"; then
        if ! grep -q -i "$MAC" "$file"; then
            echo "$MAC" >> "$file"
            zenity --info --text="MAC address $MAC added to $(basename "$file")."
        else
            zenity --warning --text="MAC address $MAC is already in $(basename "$file")."
        fi
    else
        zenity --error --text="Invalid MAC address format. Please try again."
    fi
    
    show_menu
}

# Function to remove MAC address
remove_mac_address() {
    local file=$1
    MAC=$(zenity --entry --title="Remove MAC Address" --text="Enter MAC address to remove:")
    
    if validate_mac "$MAC"; then
        if grep -q -i "$MAC" "$file"; then
            sed -i "/$MAC/d" "$file"
            zenity --info --text="MAC address $MAC removed from $(basename "$file")."
        else
            zenity --warning --text="MAC address $MAC is not found in $(basename "$file")."
        fi
    else
        zenity --error --text="Invalid MAC address format. Please try again."
    fi
    
    show_menu
}

# Function to view MAC addresses
view_mac_addresses() {
    local file=$1
    if [ -s "$file" ]; then
        MAC_LIST=$(cat "$file")
        zenity --text-info --title="$(basename "$file")" --width=600 --height=400 --text="$MAC_LIST"
    else
        zenity --info --text="$(basename "$file") is empty."
    fi
    
    show_menu
}

# Main execution
while true; do
    show_menu
done
