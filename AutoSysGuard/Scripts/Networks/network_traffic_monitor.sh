#!/bin/bash

# Function to check if nload is installed
check_nload() {
    if ! command -v nload &> /dev/null; then
        zenity --error --text="nload is not installed. Please install it using: sudo apt-get install nload"
        exit 1
    fi
}

# Function to get available network interfaces
get_network_interfaces() {
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)
    echo "$interfaces"
}

# Function to select network interface and launch nload
select_interface() {
    local interface=$(zenity --list --title="Network Traffic Monitor" --text="Select the network interface:" \
        --column="Interface" $(get_network_interfaces) --height=300 --width=400)

    if [[ -z "$interface" ]]; then
        zenity --error --text="No interface selected. Exiting."
        exit 1
    fi

    # Launch nload in a new terminal window
    gnome-terminal -- nload "$interface"
}

# Main function
main() {
    check_nload
    select_interface
}

# Run the main function
main
