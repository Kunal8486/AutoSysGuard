#!/bin/bash

# Required: Install 'arp-scan' if not already installed.
# sudo apt-get install arp-scan

INTERFACE="eth0"
CURRENT_ARP_OUTPUT="/tmp/current_arp_scan.txt"
KNOWN_ARP_FILE="/etc/arp_known_hosts.txt"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Request sudo privileges at the start
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please enter your password."
   sudo -v || { echo "Unable to obtain sudo privileges. Exiting."; exit 1; }
fi

log_message "Performing ARP scan on network interface $INTERFACE..."

# Ensure we have permission to write to the current ARP output file
sudo touch "$CURRENT_ARP_OUTPUT"
sudo chmod 644 "$CURRENT_ARP_OUTPUT"

# Run the ARP scan and redirect output to the file
sudo arp-scan --interface="$INTERFACE" --localnet > "$CURRENT_ARP_OUTPUT" 2>/dev/null

if [[ ! -f $KNOWN_ARP_FILE ]]; then
    log_message "Known hosts file not found at $KNOWN_ARP_FILE. Creating a new one."
    sudo cp "$CURRENT_ARP_OUTPUT" "$KNOWN_ARP_FILE"
    sudo chmod 644 "$KNOWN_ARP_FILE"
    log_message "Known hosts file created. Please rerun the script."
    exit 1
fi

log_message "Comparing current ARP scan results with known valid MAC addresses..."

while read -r ip mac _; do
    if [[ "$ip" != "Interface" && "$ip" != "Ending" ]]; then
        known_mac=$(grep "$ip" "$KNOWN_ARP_FILE" | awk '{print $2}')
        
        if [[ -z "$known_mac" ]]; then
            log_message "New device detected: $ip ($mac) - Not in the known hosts file."
        elif [[ "$known_mac" != "$mac" ]]; then
            log_message "WARNING: Potential ARP Spoofing detected for $ip! Expected $known_mac but found $mac."
        fi
    fi
done < "$CURRENT_ARP_OUTPUT"

log_message "ARP spoofing detection completed."
