#!/bin/bash

# Check for differences between the on-disk and running configurations
echo "Checking for differences between on-disk and running configurations..."
if augenrules --check | grep -q "No change"; then
    echo "The on-disk and running configurations are consistent."
else
    echo "Differences found between on-disk and running configurations."
    
    # Load the rules to merge them
    echo "Merging and loading all rules..."
    augenrules --load

    # Check if a reboot is required to apply the changes
    if [[ $(auditctl -s | grep "enabled") =~ "2" ]]; then
        echo "Reboot required to load rules."
    else
        echo "Audit rules loaded successfully."
    fi
fi
