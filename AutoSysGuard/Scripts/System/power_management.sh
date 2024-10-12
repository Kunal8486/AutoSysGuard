#!/bin/bash

# Function to monitor power usage (for all power supply types)
power_usage_monitor() {
    echo "=== Power Usage Monitoring ==="

    # Check if any power supply exists
    if [ -d /sys/class/power_supply ]; then
        for supply in /sys/class/power_supply/*; do
            name=$(basename "$supply")
            type=$(cat "$supply/type")
            echo "Power Supply: $name"
            echo "Type: $type"

            if [ "$type" == "Battery" ]; then
                capacity=$(cat "$supply/capacity")
                status=$(cat "$supply/status")
                voltage=$(cat "$supply/voltage_now")
                power=$(cat "$supply/power_now")

                echo "Battery Capacity: $capacity%"
                echo "Battery Status: $status"
                echo "Battery Voltage: $((voltage/1000)) mV"
                echo "Battery Power Consumption: $((power/1000)) mW"
            elif [ "$type" == "Mains" ]; then
                online=$(cat "$supply/online")
                echo "AC Power Status: $( [ "$online" == "1" ] && echo "Connected" || echo "Disconnected")"
            else
                echo "Unknown power supply type: $type"
            fi
            echo ""
        done
    else
        echo "No power supply detected or power management unavailable."
    fi
}

# Function to manage power modes
power_mode_management() {
    echo "=== Power Mode Management ==="
    echo "1) Suspend"
    echo "2) Hibernate"
    echo "3) Sleep"
    echo "4) Cancel"

    read -p "Choose an option (1-4): " choice

    case $choice in
        1)
            echo "Suspending the system..."
            systemctl suspend
            ;;
        2)
            echo "Hibernating the system..."
            systemctl hibernate
            ;;
        3)
            echo "Putting the system to sleep..."
            systemctl hybrid-sleep
            ;;
        4)
            echo "Operation canceled."
            ;;
        *)
            echo "Invalid option. Exiting."
            ;;
    esac
}

# Main script execution
echo "=== Power Management Script ==="
power_usage_monitor

echo "Would you like to manage power modes? (y/n)"
read choice
if [ "$choice" == "y" ]; then
    power_mode_management
else
    echo "Exiting script."
fi
