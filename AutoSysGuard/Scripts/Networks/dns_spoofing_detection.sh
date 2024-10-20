#!/bin/bash

# Path to the dns_spoof_detector.sh script
SCRIPT_PATH="./AutoSysGuard/Scripts/Networks/dns_snoffing.sh"

# Check if the script exists
if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Error: Script $SCRIPT_PATH not found!"
    exit 1
fi

# Check if user is running the script with sudo
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Run the script in an external terminal using GNOME Terminal, Konsole, or XTerm
# You can replace gnome-terminal with your preferred terminal emulator (e.g., konsole or xterm)

if command -v gnome-terminal &> /dev/null; then
    gnome-terminal -- bash -c "sudo $SCRIPT_PATH; exit"
elif command -v konsole &> /dev/null; then
    konsole -e "sudo $SCRIPT_PATH; exit"
elif command -v xterm &> /dev/null; then
    xterm -e "sudo $SCRIPT_PATH; exit"
else
    echo "No supported terminal emulator found. Please install gnome-terminal, konsole, or xterm."
    exit 1
fi
