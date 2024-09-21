#!/bin/bash
while true; do
  echo "Monitoring RAM..."
  free -h | awk 'NR==1{print ""; print "Memory Usage:"} NR==2{printf "Total: %s, Used: %s, Free: %s\n", $2, $3, $4}'
  echo "-----------------------"
  sleep 1 
  echo -e "\033[2J"  # Clear screen in terminal (marker to clear GUI)

done
