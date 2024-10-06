#!/bin/bash

# Function to check root privileges
check_root() {
if [ "$EUID" -ne 0 ]; then
zenity --error --text="This script must be run as root." --title="Permission Denied"
exit 1
fi
}

# Function to get network interfaces and IP addresses
check_interfaces() {
zenity --info --text="Listing Network Interfaces and IP Addresses" --title="Network Segmentation Audit"
interfaces=$(ip -br a | grep -v lo)
zenity --info --text="$interfaces" --title="Network Interfaces"
}

# Function to check subnet routing table
check_routes() {
zenity --info --text="Checking Routing Table" --title="Routing Table"
routes=$(ip route show)
zenity --info --text="$routes" --title="Routing Table"
}

# Function to check firewall rules
check_firewall() {
if command -v iptables >/dev/null 2>&1; then
firewall_rules=$(iptables -L)
if [ -z "$firewall_rules" ]; then
zenity --warning --text="No iptables firewall rules detected!" --title="Firewall Rules"
else
zenity --info --text="Firewall Rules Found!" --title="Firewall Rules"
zenity --info --text="$firewall_rules" --title="Firewall Rules"
fi
else
zenity --warning --text="iptables not installed or detected on this system." --title="Firewall Check"
fi
}

# Function to check for subnet conflicts
check_subnet_conflicts() {
subnets=$(ip -4 addr show | grep inet | awk '{print $2}')
conflicts_found=false
for subnet1 in $subnets; do
for subnet2 in $subnets; do
if [[ "$subnet1" != "$subnet2" ]]; then
if ipcalc "$subnet1" "$subnet2" >/dev/null 2>&1; then
zenity --error --text="Conflict detected: $subnet1 overlaps with $subnet2." --title="Subnet Conflict"
conflicts_found=true
fi
fi
done
done
if [ "$conflicts_found" = false ]; then
zenity --info --text="No subnet conflicts found!" --title="Subnet Audit"
fi
}

# Function to check VLAN configuration
check_vlan() {
if command -v ip >/dev/null 2>&1; then
vlan_info=$(ip -d link show | grep vlan)
if [ -z "$vlan_info" ]; then
zenity --warning --text="No VLANs detected on the system!" --title="VLAN Audit"
else
zenity --info --text="VLANs detected:\n$vlan_info" --title="VLAN Audit"
fi
else
zenity --warning --text="ip tool not installed or detected on this system." --title="VLAN Audit"
fi
}

# Main function to run the audit
run_audit() {
check_root
check_interfaces
check_routes
check_firewall
check_subnet_conflicts
check_vlan
zenity --info --text="Network Segmentation Audit Completed." --title="Audit Complete"
}

# Start the audit
run_audit
