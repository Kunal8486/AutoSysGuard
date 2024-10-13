#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   zenity --error --text="This script must be run as root. Please use sudo or switch to the root user."
   exit 1
fi

# Function to log the output of each script
log_output() {
   local script_name="$1"
   local log_file="execution_log.txt"

   echo "Executing $script_name..."
   echo "======================" >> "$log_file"
   echo "Executing $script_name" >> "$log_file"

   # Run the script and log output
   if [[ "$script_name" == *.sh ]]; then
       bash "$script_name" >> "$log_file" 2>&1
   elif [[ "$script_name" == *.py ]]; then
       python3 "$script_name" >> "$log_file" 2>&1
   else
       echo "Unknown script type: $script_name" >> "$log_file"
   fi

   if [[ $? -eq 0 ]]; then
       echo "$script_name executed successfully." | tee -a "$log_file"
   else
       echo "Error executing $script_name. Check the log for details." | tee -a "$log_file"
   fi
}

# Function to run all scripts in a folder
run_all_scripts() {
   local folder_path="$1"

   # Ensure the folder exists
   if [[ ! -d "$folder_path" ]]; then
      zenity --error --text="The folder $folder_path does not exist."
      exit 1
   fi

   # Find all .sh and .py scripts in the folder
   scripts=$(find "$folder_path" -type f \( -name "*.sh" -o -name "*.py" \))

   if [[ -z "$scripts" ]]; then
      zenity --info --text="No scripts found in the folder: $folder_path"
      return
   fi

   # Run each script
   for script in $scripts; do
      log_output "$script"
   done
}

# Function to detect subdirectories and run scripts in them
run_scripts_in_all_folders() {
    local base_dir="$1"

    # Get the list of all folders in the base directory
    folders=$(find "$base_dir" -maxdepth 1 -mindepth 1 -type d)

    if [[ -z "$folders" ]]; then
        zenity --error --text="No folders found in the current directory: $base_dir"
        exit 1
    fi

    # For each folder, run the scripts
    for folder in $folders; do
        zenity --info --text="Running scripts in folder: $folder"
        run_all_scripts "$folder"
    done
}

# Main script logic
base_dir="$(pwd)"

# Ask user if they want to run scripts from all folders in the current directory
response=$(zenity --question --text="Run scripts from all folders in the current directory: $base_dir?" --ok-label="Yes" --cancel-label="No")

if [[ $? -eq 0 ]]; then
    run_scripts_in_all_folders "$base_dir"
else
    zenity --info --text="Operation canceled."
    exit 1
fi

zenity --info --text="All scripts executed. Check execution_log.txt for details."
