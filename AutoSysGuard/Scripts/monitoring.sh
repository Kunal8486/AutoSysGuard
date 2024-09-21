#!/bin/bash

# Monitor CPU, Memory, and Disk Usage
LOG_FILE="/var/log/autosysguard/monitoring.log"
mkdir -p /var/log/autosysguard

while true; do
    echo "System Monitoring - $(date)" >> "$LOG_FILE"
    
    # CPU Usage
    echo "CPU Usage:" >> "$LOG_FILE"
    top -b -n1 | grep "Cpu(s)" >> "$LOG_FILE"
    
    # Memory Usage
    echo "Memory Usage:" >> "$LOG_FILE"
    free -m >> "$LOG_FILE"
    
    # Disk Usage
    echo "Disk Usage:" >> "$LOG_FILE"
    df -h >> "$LOG_FILE"
    
    echo "-----------------------" >> "$LOG_FILE"
    
    # Sleep for 1 minute
    sleep 60
done
