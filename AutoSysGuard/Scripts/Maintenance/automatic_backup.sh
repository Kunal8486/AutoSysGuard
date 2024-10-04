#!/bin/bash

# Function to get the time from user (Hour and Minute)
get_backup_time() {
    backup_time=$(zenity --entry --title="Backup Time" --text="Enter time for backup in HH:MM format (24-hour clock)")
    if [ $? -ne 0 ]; then
        zenity --error --text="Backup time selection cancelled."
        exit 1
    fi

    # Validate the time format (HH:MM)
    if ! [[ "$backup_time" =~ ^([01]?[0-9]|2[0-3]):([0-5]?[0-9])$ ]]; then
        zenity --error --text="Invalid time format. Please enter a valid time (HH:MM)."
        exit 1
    fi
}

# Ask the user to choose the frequency of the backup using a list
schedule=$(zenity --list --title="Choose Backup Schedule" --text="Select how often you want to schedule the backup" --column="Frequency" "Daily" "Weekly" "Monthly" --width=300 --height=200)

# Check if the user canceled the selection
if [ $? -ne 0 ]; then
    zenity --error --text="Backup scheduling cancelled."
    exit 1
fi

# Get the time for backup
get_backup_time

# Split the backup_time into hour and minute
hour=$(echo $backup_time | cut -d':' -f1)
minute=$(echo $backup_time | cut -d':' -f2)

# Backup script path (absolute path)
backup_script="system_backup.sh"

# Construct the cron job time based on the user's frequency selection
case $schedule in
    "Daily")
        cron_time="$minute $hour * * *"  # Daily at selected time
        ;;
    "Weekly")
        selected_day=$(zenity --calendar --title="Select Backup Day" --text="Select the day for the weekly backup" --date-format="%u")
        if [ $? -ne 0 ]; then
            zenity --error --text="Day selection cancelled."
            exit 1
        fi
        cron_time="$minute $hour * * $selected_day"  # Weekly on selected day and time
        ;;
    "Monthly")
        selected_day=$(zenity --calendar --title="Select Backup Day" --text="Select the day of the month for the monthly backup" --date-format="%d")
        if [ $? -ne 0 ]; then
            zenity --error --text="Day selection cancelled."
            exit 1
        fi
        cron_time="$minute $hour $selected_day * *"  # Monthly on selected day of month and time
        ;;
    *)
        zenity --error --text="Invalid option selected."
        exit 1
        ;;
esac

# Add the cron job to schedule the backup, and check for errors
(crontab -l 2>/dev/null; echo "$cron_time bash $backup_script > /path/to/backup.log 2>&1") | crontab -
if [ $? -eq 0 ]; then
    zenity --info --text="Backup has been scheduled $schedule at $backup_time."
else
    zenity --error --text="Failed to schedule the backup. Please check cron settings."
fi
