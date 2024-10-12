#!/bin/bash

# Function to check if the script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root" 
        exit 1
    fi
}

# Function to run the specified script in a new terminal
run_in_new_terminal() {
    local script_to_run="$1"

    # Check if the terminal emulator is available
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "$script_to_run; echo 'Press Enter to exit...'; read"
    elif command -v xterm &> /dev/null; then
        xterm -e "bash -c '$script_to_run; echo Press Enter to exit...; read'"
    elif command -v konsole &> /dev/null; then
        konsole -e "bash -c '$script_to_run; echo Press Enter to exit...; read'"
    else
        echo "No supported terminal emulator found. Please install gnome-terminal, xterm, or konsole."
        exit 1
    fi
}

# Main script execution
check_root

# Specify the script to run in a new terminal
script_to_run="AutoSysGuard/Scripts/System/service_management.sh"  # Change this to the script you want to run
run_in_new_terminal "$script_to_run"

# Wait for the new terminal to finish before exiting
wait
echo "Exiting the script."
