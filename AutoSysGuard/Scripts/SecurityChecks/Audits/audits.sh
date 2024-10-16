#!/bin/bash

# Base folder where CIS Benchmark navigation is allowed
BASE_DIR="$PWD/AutoSysGuard/Scripts/SecurityChecks/Audits/AuditScripts"

# Function to get the current terminal size (rows and columns)
get_terminal_size() {
    local size
    size=$(stty size)   # Get terminal size in format "rows columns"
    HEIGHT=$(echo "$size" | cut -d' ' -f1)  # Extract the number of rows
    WIDTH=$(echo "$size" | cut -d' ' -f2)   # Extract the number of columns

    # Set dialog box size to fill most of the terminal
    DIALOG_HEIGHT=$((HEIGHT - 10))  # Leave some margin
    DIALOG_WIDTH=$((WIDTH - 4))      # Leave some margin
}

# Function to display CIS Benchmark script options and execute selected ones
navigate_and_run() {
    local current_dir="$1"
    local search_term=""
    
    while true; do
        # Get a sorted list of CIS Benchmark scripts (.sh files) in the current directory (including subdirectories)
        scripts=($(find "$current_dir" -type f -name "*.sh" | sort))

        if [ ${#scripts[@]} -eq 0 ]; then
            dialog --msgbox "No CIS Benchmark scripts (.sh) were found in this folder." 10 50
            return
        fi

        # Filter scripts based on search term if provided
        if [ -n "$search_term" ]; then
            scripts=($(echo "${scripts[@]}" | grep -i "$search_term"))
        fi

        # Prepare array of script names for dialog (filenames only, sorted alphabetically)
        choices=()
        for script in "${scripts[@]}"; do
            script_name=$(basename "$script") # Get filename only
            choices+=("$script_name" "" "off") # Add filename to the list with "off" state
        done

        # Display checklist dialog for multi-selection of CIS Benchmark scripts
        selected_scripts=$(dialog --title "Select CIS Benchmark Scripts" --checklist \
            "Please select one or more CIS Benchmark scripts to run (.sh):" $DIALOG_HEIGHT $DIALOG_WIDTH 10 \
            "${choices[@]}" 3>&1 1>&2 2>&3)

        # Check for user cancellation
        if [ $? -ne 0 ]; then
            break
        fi

        # Prompt for search term within the same dialog
        search_term=$(dialog --title "Search CIS Benchmark Scripts" --inputbox \
            "Enter search term (or leave empty to see all):" 8 60 "$search_term" 3>&1 1>&2 2>&3)

        # If user cancels the search input, exit the loop
        if [ $? -ne 0 ]; then
            break
        fi

        # If scripts were selected, confirm execution
        if [ -n "$selected_scripts" ]; then
            IFS=" " read -r -a selected_scripts_array <<< "$selected_scripts" # Convert selected scripts to array

            # Build confirmation message
            confirm_message="You have selected the following CIS Benchmark scripts for execution:\n"
            for script_name in "${selected_scripts_array[@]}"; do
                confirm_message+="$script_name\n"
            done
            confirm_message+="\nWould you like to proceed with executing these scripts?"

            # Ask for confirmation before running the scripts
            dialog --title "Execution Confirmation" --yesno "$confirm_message" 15 60
            response=$?

            # If confirmed, execute each selected script
            if [ $response -eq 0 ]; then
                clear
                for script_name in "${selected_scripts_array[@]}"; do
                    script_path=$(find "$current_dir" -name "$script_name") # Get full path for execution
                    echo "Running CIS Benchmark script: $script_name"
                    bash "$script_path"
                done
                dialog --msgbox "CIS Benchmark scripts execution completed." 6 40
            else
                dialog --msgbox "Script execution was cancelled." 6 40
            fi
        fi
    done
}

# Main loop to navigate directories and select CIS Benchmark scripts
while true; do
    get_terminal_size  # Get current terminal dimensions

    # Allow user to select directories to navigate within the base folder
    folder=$(dialog --title "CIS Benchmark Navigator" --dselect "$BASE_DIR/" $DIALOG_HEIGHT $DIALOG_WIDTH 3>&1 1>&2 2>&3)

    # Ensure that the selected folder is within the base directory
    if [[ "$folder" != "$BASE_DIR"* ]]; then
        dialog --msgbox "You cannot navigate outside the designated CIS Benchmark directory." 10 50
        continue
    fi

    # Check if folder was selected, break if no folder selected
    if [ -z "$folder" ]; then
        break
    fi

    # Call function to navigate and run script in the selected folder
    navigate_and_run "$folder"
done

# Clean up dialog interface and exit
clear
