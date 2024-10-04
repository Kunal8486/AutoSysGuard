#!/bin/bash

LOGFILE="firewall_changes.log"

# Function to log changes
log_change() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOGFILE"
}

# Function to display current firewall rules in the terminal
display_firewall_rules() {
    echo "Current Firewall Rules:"
    sudo iptables -L -n -v
}


# Function to validate the rule syntax
validate_rule() {
    if [[ ! "$1" =~ ^(-A|-D)\s+ ]]; then
        zenity --error --text="Invalid rule syntax. Rules must start with '-A' (add) or '-D' (delete)."
        return 1
    fi
    return 0
}

# Function to add a new firewall rule
add_firewall_rule() {
    local rule
    rule=$(zenity --entry --title="Add Firewall Rule" --text="Enter the rule (e.g., -A INPUT -p tcp --dport 80 -j ACCEPT):")
    if [[ -n "$rule" && $(validate_rule "$rule") == 0 ]]; then
        sudo iptables $rule
        log_change "Added rule: $rule"
        zenity --info --text="Rule added successfully."
    fi
}

# Function to delete a firewall rule
delete_firewall_rule() {
    local rule
    rule=$(zenity --entry --title="Delete Firewall Rule" --text="Enter the rule to delete (e.g., -D INPUT -p tcp --dport 80 -j ACCEPT):")
    if [[ -n "$rule" && $(validate_rule "$rule") == 0 ]]; then
        sudo iptables $rule
        log_change "Deleted rule: $rule"
        zenity --info --text="Rule deleted successfully."
    fi
}

# Function to view specific rule details
view_firewall_rule() {
    local rule
    rule=$(zenity --entry --title="View Firewall Rule" --text="Enter the rule to view (e.g., INPUT, OUTPUT):")
    if [[ -n "$rule" ]]; then
        sudo iptables -L $rule -n -v
    else
        zenity --error --text="No rule entered."
    fi
}

# Function to backup current firewall rules
backup_firewall_rules() {
    sudo iptables-save > iptables_backup_$(date +"%Y%m%d_%H%M%S").bak
    zenity --info --text="Firewall rules backed up successfully."
}

# Function to restore firewall rules from a backup
restore_firewall_rules() {
    local file
    file=$(zenity --file-selection --title="Select Backup File" --file-filter="*.bak")
    if [[ -n "$file" ]]; then
        sudo iptables-restore < "$file"
        log_change "Restored rules from backup: $file"
        zenity --info --text="Firewall rules restored successfully."
    fi
}

# Function to export firewall rules to a file named "Firewall Table.txt"
export_firewall_rules() {
    local file="Firewall Table.txt"  # Define the fixed filename
    if sudo iptables-save > "$file"; then
        zenity --info --text="Firewall rules exported successfully to $file."
    else
        zenity --error --text="Failed to export firewall rules."
    fi
}



# Function to import firewall rules from a file
import_firewall_rules() {
    local file
    file=$(zenity --file-selection --title="Select Rules File" --file-filter="*.txt")
    if [[ -n "$file" ]]; then
        sudo iptables-restore < "$file"
        log_change "Imported rules from file: $file"
        zenity --info --text="Firewall rules imported successfully."
    fi
}

# Function to check firewall status
check_firewall_status() {
    if sudo iptables -L &> /dev/null; then
        zenity --info --text="Firewall is active."
    else
        zenity --info --text="Firewall is inactive."
    fi
}

# Function to provide help
show_help() {
    zenity --info --text="Common iptables rules examples:\n
-A INPUT -p tcp --dport 80 -j ACCEPT: Allow HTTP traffic.\n
-A INPUT -p tcp --dport 22 -j ACCEPT: Allow SSH traffic.\n
-D INPUT -p tcp --dport 80 -j ACCEPT: Delete HTTP rule."
}

# Main menu
while true; do
    choice=$(zenity --list --title="Firewall Configuration" --column="Options" \
        "Display Current Rules" \
        "Add Rule" \
        "Delete Rule" \
        "View Specific Rule" \
        "Backup Firewall Rules" \
        "Restore Firewall Rules" \
        "Export Firewall Rules" \
        "Import Firewall Rules" \
        "Check Firewall Status" \
        "Help" \
        "Exit")
    
    case $choice in
        "Display Current Rules")
            display_firewall_rules | zenity --text-info --title="Current Firewall Rules" --width=600 --height=400
            ;;
        "Add Rule")
            add_firewall_rule
            ;;
        "Delete Rule")
            delete_firewall_rule
            ;;
        "View Specific Rule")
            view_firewall_rule | zenity --text-info --title="Firewall Rule Details" --width=600 --height=400
            ;;
        "Backup Firewall Rules")
            backup_firewall_rules
            ;;
        "Restore Firewall Rules")
            restore_firewall_rules
            ;;
        "Export Firewall Rules")
            export_firewall_rules
            ;;
        "Import Firewall Rules")
            import_firewall_rules
            ;;
        "Check Firewall Status")
            check_firewall_status
            ;;
        "Help")
            show_help
            ;;
        "Exit")
            break
            ;;
        *)
            zenity --error --text="Invalid option. Please try again."
            ;;
    esac
done

echo "Firewall configuration script completed."
