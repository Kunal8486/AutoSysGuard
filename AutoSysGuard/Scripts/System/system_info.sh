#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# OS Information
echo "==== OS Information ===="
echo "Hostname: $(hostname)"
echo "Operating System: $(lsb_release -d | cut -f2)"
echo "Kernel Version: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "System Uptime: $(uptime -p)"

# Hardware Information
echo -e "\n==== Hardware Information ===="
echo "CPU Info: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)"
echo "Number of CPUs: $(nproc)"
echo "Total Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Available Memory: $(free -h | grep Mem | awk '{print $7}')"
echo "Total Swap: $(free -h | grep Swap | awk '{print $2}')"
echo "Available Swap: $(free -h | grep Swap | awk '{print $4}')"

# BIOS Information
echo -e "\n==== BIOS Information ===="
if command_exists dmidecode; then
    sudo dmidecode -t bios | grep -E "Vendor|Version|Release Date"
else
    echo "dmidecode command not found. Please install dmidecode."
fi

# Motherboard Information
echo -e "\n==== Motherboard Information ===="
if command_exists dmidecode; then
    sudo dmidecode -t baseboard | grep -E "Manufacturer|Product Name|Version"
else
    echo "dmidecode command not found. Please install dmidecode."
fi

# GPU Information
echo -e "\n==== GPU Information ===="
if command_exists lspci; then
    lspci | grep -E "VGA|3D|Display"
else
    echo "lspci command not found. Please install pciutils."
fi

# Disk Usage
echo -e "\n==== Disk Usage ===="
df -h | grep "^/dev/"

# Mounted File Systems
echo -e "\n==== Mounted File Systems ===="
lsblk

# Network Information
echo -e "\n==== Network Information ===="
if command_exists ip; then
    echo "IP Addresses: $(ip addr | grep 'inet ' | awk '{print $2}')"
    echo -e "\nNetwork Interfaces:"
    ip link show | awk -F': ' '/^[0-9]+: / {print $2}'
    echo -e "\nRouting Table:"
    ip route
else
    echo "IP command not found."
fi

# DNS Configuration
echo -e "\n==== DNS Configuration ===="
if command_exists systemd-resolve; then
    systemd-resolve --status | grep 'DNS Servers' -A 2
elif command_exists resolvectl; then
    resolvectl status | grep 'DNS Servers' -A 2
elif [ -f /etc/resolv.conf ]; then
    echo "DNS Servers: $(grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}')"
else
    echo "DNS configuration not found."
fi

# End of script
