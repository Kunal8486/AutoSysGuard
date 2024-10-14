#!/bin/bash

# Title: Security Anomaly Detection Tool
# Author: Kunal Kumar
# Version: 1.0
# Date: 2024-10-14
# Description: Bash-based anomaly detection for security logs using basic statistics and Zenity for the GUI.

# Function to display the main menu
show_main_menu() {
    choice=$(zenity --list --title="Security Anomaly Detection" \
                    --column="Select Action" \
                    "Upload Security Log" \
                    "Perform Anomaly Detection" \
                    "Exit")

    case $choice in
        "Upload Security Log")
            upload_log
            ;;
        "Perform Anomaly Detection")
            perform_anomaly_detection
            ;;
        "Exit")
            exit 0
            ;;
        *)
            zenity --error --text="Invalid selection."
            exit 1
            ;;
    esac
}

# Function to upload the security log file
upload_log() {
    log_file=$(zenity --file-selection --title="Select Security Log File (CSV Format)")
    if [[ ! -f "$log_file" ]]; then
        zenity --error --text="Invalid file. Please select a valid log file."
        exit 1
    fi
    echo "Log file uploaded: $log_file"
    zenity --info --text="Log file uploaded successfully."
}

# Function to calculate basic statistics (mean, std deviation) and detect anomalies in security logs
perform_anomaly_detection() {
    if [[ -z "$log_file" ]]; then
        zenity --error --text="No log file uploaded. Please upload a log file first."
        exit 1
    fi

    threshold=$(zenity --entry --title="Anomaly Detection Threshold" --text="Enter the Z-score threshold for anomalies (e.g., 2.5):")

    # Ensure the threshold is a valid number
    if ! [[ "$threshold" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        zenity --error --text="Invalid threshold value. Please enter a valid number."
        exit 1
    fi

    # Perform basic anomaly detection using awk (for numeric CSV data in security logs)
    result=$(awk -v threshold="$threshold" '
    BEGIN {
        FS=",";  # Assuming a CSV file with comma-separated values
        sum=0; sumsq=0; n=0;
    }
    NR > 1 {  # Skip the header (assuming the first row is a header with field names like timestamp, login_attempts, etc.)
        for (i = 2; i <= NF; i++) {  # Start from the second column (bypassing timestamps if present)
            val = $i;
            sum += val;
            sumsq += (val * val);
            n++;
        }
    }
    END {
        if (n == 0) {
            print "No data to process.";
            exit;
        }

        mean = sum / n;
        variance = (sumsq / n) - (mean * mean);
        stdev = sqrt(variance);
        print "Mean:", mean, "Standard Deviation:", stdev;

        # Detect anomalies based on Z-score
        anomaly_count = 0;
        anomaly_records = "";  # Store anomaly records for output
        for (i = 2; i <= NF; i++) {
            zscore = ($i - mean) / stdev;
            if (zscore > threshold || zscore < -threshold) {
                anomaly_count++;
                anomaly_records = anomaly_records "\nAnomaly found in record " NR ", Value: " $i ", Z-score: " zscore;
            }
        }
        if (anomaly_count == 0) {
            print "No anomalies found.";
        } else {
            print anomaly_count, "anomalies detected:" anomaly_records;
        }
    }' "$log_file")

    # Display the result to the user using Zenity
    zenity --info --title="Anomaly Detection Results" --text="$result"

    # Optional: Log anomalies to a separate file (for future analysis)
    echo "$result" >> security_anomalies.log
    zenity --info --text="Results logged to security_anomalies.log"
}

# Main script execution starts here
show_main_menu
