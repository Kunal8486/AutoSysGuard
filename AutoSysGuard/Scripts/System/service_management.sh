#!/bin/bash

# Log file directory
LOG_DIR="./log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/service_management.log"

# Function to log actions
log_action() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Function to display active services
view_services() {
    services=$(systemctl list-units --type=service --state=running | awk '{print $1}' | tr '\n' ' ')
    whiptail --msgbox "Active Services:\n$services" 15 60
}

# Function to start a service
start_service() {
    service_name=$(whiptail --inputbox "Enter the service name to start:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$service_name" ]; then
        sudo systemctl start "$service_name"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Service $service_name started successfully." 10 60
            log_action "Started service: $service_name"
        else
            whiptail --msgbox "Failed to start service $service_name." 10 60
        fi
    fi
}

# Function to stop a service
stop_service() {
    service_name=$(whiptail --inputbox "Enter the service name to stop:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$service_name" ]; then
        sudo systemctl stop "$service_name"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Service $service_name stopped successfully." 10 60
            log_action "Stopped service: $service_name"
        else
            whiptail --msgbox "Failed to stop service $service_name." 10 60
        fi
    fi
}

# Function to restart a service
restart_service() {
    service_name=$(whiptail --inputbox "Enter the service name to restart:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$service_name" ]; then
        sudo systemctl restart "$service_name"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Service $service_name restarted successfully." 10 60
            log_action "Restarted service: $service_name"
        else
            whiptail --msgbox "Failed to restart service $service_name." 10 60
        fi
    fi
}

# Function to enable a service at boot
enable_service() {
    service_name=$(whiptail --inputbox "Enter the service name to enable at boot:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$service_name" ]; then
        sudo systemctl enable "$service_name"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Service $service_name enabled to start at boot." 10 60
            log_action "Enabled service $service_name to start at boot."
        else
            whiptail --msgbox "Failed to enable service $service_name." 10 60
        fi
    fi
}

# Function to disable a service at boot
disable_service() {
    service_name=$(whiptail --inputbox "Enter the service name to disable at boot:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$service_name" ]; then
        sudo systemctl disable "$service_name"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Service $service_name disabled from starting at boot." 10 60
            log_action "Disabled service $service_name from starting at boot."
        else
            whiptail --msgbox "Failed to disable service $service_name." 10 60
        fi
    fi
}

# Main menu
while true; do
    action=$(whiptail --menu "Service Management" 15 60 10 \
        "1" "View Active Services" \
        "2" "Start Service" \
        "3" "Stop Service" \
        "4" "Restart Service" \
        "5" "Enable Service at Boot" \
        "6" "Disable Service at Boot" \
        "7" "Exit" 3>&1 1>&2 2>&3)

    case $action in
        1)
            view_services
            ;;
        2)
            start_service
            ;;
        3)
            stop_service
            ;;
        4)
            restart_service
            ;;
        5)
            enable_service
            ;;
        6)
            disable_service
            ;;
        7)
            break
            ;;
        *)
            whiptail --msgbox "Invalid selection." 10 60
            ;;
    esac
done
