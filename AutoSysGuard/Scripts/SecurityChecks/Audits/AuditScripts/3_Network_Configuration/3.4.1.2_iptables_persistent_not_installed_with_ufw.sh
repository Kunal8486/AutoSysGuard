# 3.4.1.2 Ensure iptables-persistent is not installed with ufw (Automated)
#!/bin/bash

# Check if iptables-persistent is installed
if dpkg-query -s iptables-persistent &>/dev/null; then
    echo "The iptables-persistent package is installed."
else
    echo "The iptables-persistent package is not installed."
    echo "No action needed."
    exit 0
fi

# Prompt user for remediation
read -p "Do you want to remove the iptables-persistent package? (y/n): " choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Removing iptables-persistent package..."
    sudo apt purge iptables-persistent
    echo "The iptables-persistent package has been removed."
else
    echo "No action taken. The iptables-persistent package remains installed."
fi
