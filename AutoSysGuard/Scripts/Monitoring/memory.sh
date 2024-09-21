#!/bin/bash
while true; do
    memory_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
    log_message "Memory Usage: $memory_usage%"
    sleep 5 
done
