#!/bin/bash
while true; do
    disk_usage=$(df -h | grep '/dev/sda1' | awk '{print $5}' | sed 's/%//')
    echo "Disk Usage: $disk_usage%"
    sleep 5  # Update interval
done
