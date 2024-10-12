# 2.3.4 Ensure telnet client is not installed (Automated)

#!/bin/bash

# Function to check if telnet client is installed
check_telnet_installed() {
    dpkg-query -W -f='${Status}' telnet 2>/dev/null | grep -q "install ok installed"
}

# Check if telnet is installed
if check_telnet_installed; then
    echo "Telnet client is currently installed."
    echo "Uninstalling telnet client..."
    sudo apt-get purge --auto-remove telnet -y
    echo "Telnet client has been successfully removed."
else
    echo "Telnet client is not installed."
fi

# Optionally, provide a summary of the package status
echo "Verifying package status..."
dpkg-query -W -f='${binary:Package}\t${Status}\n' telnet
