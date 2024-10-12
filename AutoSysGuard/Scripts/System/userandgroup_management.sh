#!/bin/bash

# Log file directory
LOG_DIR="./log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/user_group_management.log"

# Function to log actions
log_action() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

# Function to add a user
add_user() {
    username=$(whiptail --inputbox "Enter the new username:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$username" ]; then
        sudo useradd "$username"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "User $username added successfully." 10 60
            log_action "Added user: $username"
        else
            whiptail --msgbox "Failed to add user $username." 10 60
        fi
    fi
}

# Function to remove a user
remove_user() {
    username=$(whiptail --inputbox "Enter the username to remove:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$username" ]; then
        sudo userdel "$username"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "User $username removed successfully." 10 60
            log_action "Removed user: $username"
        else
            whiptail --msgbox "Failed to remove user $username." 10 60
        fi
    fi
}

# Function to modify a user
modify_user() {
    username=$(whiptail --inputbox "Enter the username to modify:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$username" ]; then
        new_shell=$(whiptail --inputbox "Enter new shell for $username (e.g., /bin/bash):" 10 60 3>&1 1>&2 2>&3)
        sudo usermod --shell "$new_shell" "$username"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "User $username shell changed to $new_shell." 10 60
            log_action "Modified user $username: Shell changed to $new_shell"
        else
            whiptail --msgbox "Failed to modify user $username." 10 60
        fi
    fi
}

# Function to add a group
add_group() {
    groupname=$(whiptail --inputbox "Enter the new group name:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$groupname" ]; then
        sudo groupadd "$groupname"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Group $groupname added successfully." 10 60
            log_action "Added group: $groupname"
        else
            whiptail --msgbox "Failed to add group $groupname." 10 60
        fi
    fi
}

# Function to remove a group
remove_group() {
    groupname=$(whiptail --inputbox "Enter the group name to remove:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$groupname" ]; then
        sudo groupdel "$groupname"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "Group $groupname removed successfully." 10 60
            log_action "Removed group: $groupname"
        else
            whiptail --msgbox "Failed to remove group $groupname." 10 60
        fi
    fi
}

# Function to modify a group
modify_group() {
    groupname=$(whiptail --inputbox "Enter the group name to modify:" 10 60 3>&1 1>&2 2>&3)
    if [ -n "$groupname" ]; then
        username=$(whiptail --inputbox "Enter the username to add to $groupname:" 10 60 3>&1 1>&2 2>&3)
        sudo usermod -aG "$groupname" "$username"
        if [ $? -eq 0 ]; then
            whiptail --msgbox "User $username added to group $groupname." 10 60
            log_action "User $username added to group $groupname"
        else
            whiptail --msgbox "Failed to add user $username to group $groupname." 10 60
        fi
    fi
}

# Function to check sudo privileges
check_sudo_privileges() {
    sudo_users=$(getent group sudo | cut -d: -f4)
    whiptail --msgbox "Users with sudo privileges:\n$sudo_users" 15 60
    log_action "Checked sudo privileges: $sudo_users"
}

# Function to view users
view_users() {
    users=$(getent passwd | cut -d: -f1 | tr '\n' ' ')
    whiptail --msgbox "Users:\n$users" 15 60
}

# Function to view groups
view_groups() {
    groups=$(getent group | cut -d: -f1 | tr '\n' ' ')
    whiptail --msgbox "Groups:\n$groups" 15 60
}


# Main menu
while true; do
    action=$(whiptail --menu "User & Group Management" 15 60 10 \
        "1" "Add User" \
        "2" "Remove User" \
        "3" "Modify User" \
        "4" "Add Group" \
        "5" "Remove Group" \
        "6" "Modify Group" \
        "7" "Check Sudo Privileges" \
        "8" "View Users" \
        "9" "View Groups" \
        "10" "Exit" 3>&1 1>&2 2>&3)

    case $action in
        1)
            add_user
            ;;
        2)
            remove_user
            ;;
        3)
            modify_user
            ;;
        4)
            add_group
            ;;
        5)
            remove_group
            ;;
        6)
            modify_group
            ;;
        7)
            check_sudo_privileges
            ;;
        8)
            view_users
            ;;
        9)
            view_groups
            ;;
        10)
            break
            ;;
        *)
            whiptail --msgbox "Invalid selection." 10 60
            ;;
    esac
done
