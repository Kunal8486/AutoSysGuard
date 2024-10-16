#!/bin/bash

# Detect if the user is running the script as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo."
  exit
fi

# Launch the external_drive_scan.sh script in a new terminal window
gnome-terminal -- bash -c "sudo bash ./AutoSysGuard/Scripts/SecurityChecks/Audits/audits.sh; exec bash"
