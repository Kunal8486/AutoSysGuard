#!/bin/bash

# Function to check for root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        zenity --error --text="This script must be run as root." --title="Permission Denied"
        exit 1
    fi
}

# Function to get available network interfaces
get_network_interfaces() {
    local interfaces=$(ip -o link show | awk -F': ' '{print $2}' | tr '\n' ' ')
    echo "$interfaces"
}

# Function to start packet sniffing
start_sniffing() {
    local interfaces=($(get_network_interfaces))

    # Check if any interfaces were found
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        zenity --error --text="No network interfaces found." --title="Error"
        return
    fi

    # Show a selection dialog for interfaces
    local interface=$(zenity --list --title="Select Network Interface" --column="Interface" "${interfaces[@]}")
    if [[ -z "$interface" ]]; then
        zenity --error --text="No interface selected."
        return
    fi

    local output_file="$HOME/packet_sniffing.pcap"

    # Start tcpdump
    tcpdump -i "$interface" -w "$output_file" -c 100 &
    local tcpdump_pid=$!

    # Check if tcpdump started successfully
    sleep 1  # Wait a moment for tcpdump to start
    if ! kill -0 "$tcpdump_pid" 2>/dev/null; then
        zenity --error --text="Failed to start tcpdump. Check your interface name or permissions." --title="Error"
        return
    fi

    zenity --info --text="Capturing packets on $interface... (Press OK to stop capturing)" --title="Packet Sniffing"

    # Attempt to stop tcpdump
    if kill -0 "$tcpdump_pid" 2>/dev/null; then
        kill -TERM "$tcpdump_pid"  # Stop tcpdump gracefully
        wait "$tcpdump_pid"  # Wait for it to terminate
    else
        zenity --error --text="tcpdump is not running. It may have exited unexpectedly." --title="Error"
        return
    fi

    zenity --info --text="Packet sniffing completed. Captured packets saved to $output_file." --title="Done"

    # Display the captured packets
    if command -v wireshark >/dev/null 2>&1; then
        wireshark "$output_file" &
    else
        zenity --info --text="Wireshark is not installed. You can find the packets in $output_file." --title="Wireshark Not Found"
    fi
}

# Main script execution
check_root
start_sniffing
