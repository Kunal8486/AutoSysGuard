#!/bin/bash

# Port Scan Script
SCAN_LOG="/var/log/autosysguard/port_scan.log"
mkdir -p /var/log/autosysguard

echo "Port Scan - $(date)" >> "$SCAN_LOG"

# Basic Port Scan using netstat
echo "Open Ports:" >> "$SCAN_LOG"
netstat -tuln | grep LISTEN >> "$SCAN_LOG"

# If nmap is installed, use it for a more detailed scan
if command -v nmap &> /dev/null; then
    echo "Detailed Port Scan using Nmap:" >> "$SCAN_LOG"
    nmap -sS -Pn localhost >> "$SCAN_LOG"
fi

echo "-----------------------" >> "$SCAN_LOG"
