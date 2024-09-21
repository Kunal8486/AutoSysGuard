#!/bin/bash
while true; do
  echo "Monitoring Disk..."
  
  # Disk Usage
  echo -e "\nDisk Usage:"
  df -h | awk 'NR==1{print $0; print "----------------------------------------"} 1'
  
  # Disk Read/Write Speed
  echo -e "\nDisk Read/Write Speed:"
  iostat -h | awk '
    NR==1 {print $0; next}
    NR==3 {printf "Reads:   %s IOPS, %s KB/s\n", $1, $2}
    NR==4 {printf "Writes:  %s IOPS, %s KB/s\n", $1, $2}
  '
  
  echo "----------------------------------------"
  sleep 1 
  echo -e "\033[2J"  # Clear screen in terminal (marker to clear GUI)

done
