#!/bin/bash

# Check if the talk client is installed
if dpkg-query -W -f='${Status}' talk 2>/dev/null | grep -q "install ok installed"; then
    echo "Talk client is currently installed."
    read -p "Do you want to uninstall the talk client? (y/n): " choice
    if [[ "$choice" == "y" ]]; then
        echo "Uninstalling talk client..."
        sudo apt-get remove --purge talk -y
        echo "Talk client has been successfully removed."
    else
        echo "Talk client remains installed."
    fi
else
    echo "Talk client is not installed."
fi
