#!/bin/bash

# Network Traffic Monitor Script
TRAFFIC_LOG="/var/log/autosysguard/network_traffic.log"
mkdir -p /var/log/autosysguard

echo "Network Traffic Monitoring - $(date)" >> "$TRAFFIC_LOG"

# Check if iftop is installed
if command -v iftop &> /dev/null; then
    echo "Monitoring network traffic with iftop..." >> "$TRAFFIC_LOG"
    sudo iftop -t -s 10 >> "$TRAFFIC_LOG"  # Runs iftop in text mode for 10 seconds
else
    echo "iftop is not installed. Please install it using 'sudo apt install iftop'." >> "$TRAFFIC_LOG"
fi

echo "-----------------------" >> "$TRAFFIC_LOG"
