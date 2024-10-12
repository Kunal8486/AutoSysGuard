#!/bin/bash

# Log file directory
LOG_DIR="./log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/performance_tuning.log"

# Function to log actions
log_action() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Function to configure CPU governor
configure_cpu_governor() {
    current_governor=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort -u)
    governor=$(whiptail --menu "Current CPU Governor: $current_governor" 15 60 3 \
        "performance" "Set to Performance" \
        "powersave" "Set to Power-Saving" \
        "exit" "Exit" 3>&1 1>&2 2>&3)

    if [ "$governor" = "performance" ] || [ "$governor" = "powersave" ]; then
        echo "$governor" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
        if [ $? -eq 0 ]; then
            whiptail --msgbox "CPU Governor set to $governor." 10 60
            log_action "Configured CPU Governor to $governor"
        else
            whiptail --msgbox "Failed to set CPU Governor to $governor." 10 60
        fi
    fi
}

# Function to optimize services
optimize_services() {
    unnecessary_services=$(systemctl list-unit-files --state=disabled | awk '{print $1}' | tr '\n' ' ')
    
    selected_service=$(whiptail --menu "Select a service to stop:" 15 60 20 $unnecessary_services 3>&1 1>&2 2>&3)
    
    if [ -n "$selected_service" ]; then
        sudo systemctl stop "$selected_service"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Service $selected_service stopped successfully." 10 60
            log_action "Stopped unnecessary service: $selected_service"
        else
            whiptail --msgbox "Failed to stop service $selected_service." 10 60
        fi
    fi
}

# Function to adjust swap settings
adjust_swap() {
    current_swappiness=$(cat /proc/sys/vm/swappiness)
    new_swappiness=$(whiptail --inputbox "Current Swappiness: $current_swappiness\n\nEnter new swappiness value (0-100):" 10 60 "$current_swappiness" 3>&1 1>&2 2>&3)

    if [[ "$new_swappiness" =~ ^[0-9]+$ ]] && [ "$new_swappiness" -ge 0 ] && [ "$new_swappiness" -le 100 ]; then
        echo "$new_swappiness" | sudo tee /proc/sys/vm/swappiness > /dev/null
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Swappiness set to $new_swappiness." 10 60
            log_action "Adjusted swappiness to $new_swappiness"
        else
            whiptail --msgbox "Failed to set swappiness to $new_swappiness." 10 60
        fi
    else
        whiptail --msgbox "Invalid value. Please enter a number between 0 and 100." 10 60
    fi
}

# Main menu
while true; do
    action=$(whiptail --menu "Performance Tuning" 15 60 10 \
        "1" "Configure CPU Governor" \
        "2" "Optimize Services" \
        "3" "Adjust Swap Settings" \
        "4" "Exit" 3>&1 1>&2 2>&3)

    case $action in
        1)
            configure_cpu_governor
            ;;
        2)
            optimize_services
            ;;
        3)
            adjust_swap
            ;;
        4)
            break
            ;;
        *)
            whiptail --msgbox "Invalid selection." 10 60
            ;;
    esac
done
