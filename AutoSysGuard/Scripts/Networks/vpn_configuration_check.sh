#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Check if VPN interface exists (common VPN interfaces: tun0, ppp0)
VPN_INTERFACE=$(ip a | grep -E 'tun0|ppp0' | awk '{print $2}' | sed 's/://')
if [ -z "$VPN_INTERFACE" ]; then
  zenity --error --text="No active VPN connection detected." --title="VPN Check"
  exit 1
fi

# Check if the VPN interface is up and running
VPN_STATUS=$(ip link show "$VPN_INTERFACE" | grep 'state UP')
if [ -z "$VPN_STATUS" ]; then
  zenity --error --text="VPN interface $VPN_INTERFACE is down." --title="VPN Check"
  exit 1
fi

# Check if the traffic is routed through the VPN (default gateway check)
DEFAULT_ROUTE=$(ip route show default | grep "$VPN_INTERFACE")
if [ -z "$DEFAULT_ROUTE" ]; then
  zenity --error --text="Traffic is not routed through the VPN interface $VPN_INTERFACE." --title="VPN Check"
  exit 1
fi

# Check public IP (should be the VPN IP, not the local IP)
PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
VPN_IP=$(curl -s https://api64.ipify.org)
if [[ "$PUBLIC_IP" == "$VPN_IP" ]]; then
  zenity --info --text="VPN is active, traffic is routed through $VPN_INTERFACE, and public IP is $VPN_IP." --title="VPN Check"
else
  zenity --error --text="Public IP does not match VPN IP. VPN traffic may not be routed correctly." --title="VPN Check"
fi
