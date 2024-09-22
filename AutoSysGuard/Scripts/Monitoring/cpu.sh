#!/bin/bash
while true; do
  echo "Monitoring CPU..."
  mpstat 1 1 | awk '/^Average:/ {printf "User: %.1f%%, System: %.1f%%, Idle: %.1f%%\n", $3, $5, $12}'
  sleep 1 
  echo -e "\033[2J"  # Clear screen in terminal (marker to clear GUI)

done
