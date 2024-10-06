#!/bin/bash

# Check if dhcping is installed
if ! command -v dhcping &> /dev/null; then
    zenity --error --text="dhcping is not installed. Please install it to proceed."
    exit 1
fi

# Function to get the local network automatically
get_local_network() {
    # Get the IP address of the first network interface
    local_ip=$(ip -o -f inet addr show | awk '{print $4}' | head -n 1)
    if [[ -z "$local_ip" ]]; then
        zenity --error --text="No active network interface found. Please connect to a network."
        exit 1
    fi
    
    # Extract the network range (e.g., 192.168.1.)
    IFS='.' read -r i1 i2 i3 i4 <<< "$local_ip"
    echo "${i1}.${i2}.${i3}."
}

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

# Function to scan for rogue DHCP servers
scan_for_rogue_servers() {
    rogue_servers=()
    
    # Scan a range of IPs
    for i in {1..254}; do
        current_ip="${LOCAL_NETWORK}${i}"
        if validate_ip "$current_ip"; then
            # Send a DHCP request with a timeout
            dhcp_response=$(sudo dhcping -c "$current_ip" -q -t 1 2>/dev/null) # 1 second timeout
            if [ $? -eq 0 ]; then
                rogue_servers+=("$current_ip")
            fi
            # Provide progress feedback
            echo "Scanning $current_ip..."
        fi
    done
    
    # Display results
    if [ ${#rogue_servers[@]} -eq 0 ]; then
        zenity --info --text="No rogue DHCP servers detected."
    else
        rogue_list=$(printf "%s\n" "${rogue_servers[@]}")
        zenity --text-info --title="Rogue DHCP Servers Detected" --width=600 --height=400 --text="The following rogue DHCP servers were detected:\n\n$rogue_list"
    fi
}

# Main logic
DEFAULT_NETWORK=$(get_local_network)
LOCAL_NETWORK=$(zenity --entry --title="Set Local Network" --text="Detected local network range: $DEFAULT_NETWORK\nEnter your local network range or leave blank to use the detected range:")

# Use detected network if user leaves it blank
if [[ -z "$LOCAL_NETWORK" ]]; then
    LOCAL_NETWORK="$DEFAULT_NETWORK"
else
    if ! validate_ip "$LOCAL_NETWORK"; then
        zenity --error --text="Invalid local network range format. Please try again."
        exit 1
    fi
fi

# Scan for rogue DHCP servers
scan_for_rogue_servers
