#!/bin/bash

# Log file
LOGFILE="arp_detection.log"

# Get the network interface from the user using Zenity
INTERFACE=$(zenity --list --title="Select Network Interface" --column="Interfaces" $(ip link show | awk -F: '$0 !~ "lo|vir|veth|docker" {print $2}' | tr -d ' '))

if [ -z "$INTERFACE" ]; then
    zenity --error --text="No interface selected. Exiting."
    exit 1
fi

echo "Selected interface: $INTERFACE"

arp_table=$(arp -n)
declare -A arp_map
spoof_count=0

while read -r line; do
    ip=$(echo $line | awk '{print $1}')
    mac=$(echo $line | awk '{print $3}')
    if [[ $ip != "" && $mac != "" ]]; then
        arp_map[$ip]+="$mac "
    fi
done <<< "$arp_table"

echo "Checking for potential ARP spoofing..."
for ip in "${!arp_map[@]}"; do
    macs=(${arp_map[$ip]})
    if [ ${#macs[@]} -gt 1 ]; then
        echo "Potential ARP Spoofing detected for IP: $ip"
        echo "Associated MAC addresses: ${arp_map[$ip]}"
        spoofing_detected=true
        spoof_count=$((spoof_count + 1))
        notify-send "ARP Spoofing Alert" "Potential ARP Spoofing detected for IP: $ip"
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Potential ARP Spoofing detected for IP: $ip" >> "$LOGFILE"
    fi
done

if [ "$spoofing_detected" = true ]; then
    echo "ARP Spoofing Detection Failed: Potential spoofing detected."
else
    echo "ARP Spoofing Detection Passed: No issues detected."
fi

echo "Summary of Detection:"
echo "Total Potential Spoofing Instances: $spoof_count"
echo "ARP Spoofing Detection completed."
