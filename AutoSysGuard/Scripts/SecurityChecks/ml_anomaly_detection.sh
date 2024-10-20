#!/bin/bash

# Check for Python and necessary packages
if ! command -v python3 &> /dev/null; then
    whiptail --msgbox "Python3 is not installed. Please install Python3 to continue." 8 45
    exit 1
fi

# Use whiptail to prompt the user to enter the CSV file path
CSV_FILE=$(whiptail --inputbox "Enter the full path to your CSV file:\n\nExample: /home/kunal/Desktop/sample_data.csv\n\n(Use terminal to navigate if needed)" 15 70 "" 3>&1 1>&2 2>&3)

# Check if the user cancelled the input
if [[ $? -ne 0 ]]; then
    exit 0
fi

# Check if the file exists
if [[ ! -f "$CSV_FILE" ]]; then
    whiptail --msgbox "The specified file does not exist. Please check the path and try again." 10 60
    exit 1
fi

# Specify the path to the anomaly_detection.py script
PYTHON_SCRIPT_PATH="./AutoSysGuard/Scripts/SecurityChecks/ml_anomaly_detection.py"

# Run the anomaly detection script and keep the terminal open
python3 "$PYTHON_SCRIPT_PATH" "$CSV_FILE"

# Inform the user the script has finished
whiptail --msgbox "Anomaly detection completed. Check the terminal for results." 10 60
