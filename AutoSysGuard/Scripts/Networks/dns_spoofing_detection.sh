#!/bin/bash

# Function to check for root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        zenity --error --text="This script must be run as root." --title="Permission Denied"
        exit 1
    fi
}

# Function to check for DNS spoofing
check_dns_spoofing() {
    local domain=$(zenity --entry --text="Enter the domain to check for spoofing (e.g., google.com):" --title="Domain Entry")
    if [[ -z "$domain" ]]; then
        zenity --error --text="No domain specified."
        return
    fi

    # Perform DNS lookup using dig
    local resolved_ip=$(dig +short "$domain" 2>/dev/null)

    if [[ -z "$resolved_ip" ]]; then
        zenity --error --text="Failed to resolve domain '$domain'. Please check the domain name." --title="Error"
        return
    fi

    # Display the resolved IP
    zenity --info --text="Resolved IP for $domain: $resolved_ip" --title="DNS Resolution"

    # Optionally, check against known legitimate IPs
    # This part can be customized as needed for your use case
    # For example:
    case "$domain" in
        "google.com")
            local known_ip="142.250.194.46"
            ;;
        "facebook.com")
            local known_ip="157.240.22.35"
            ;;
        *)
            local known_ip=""
            ;;
    esac

    if [[ -n "$known_ip" && "$resolved_ip" != "$known_ip" ]]; then
        zenity --warning --text="Warning: The resolved IP for $domain ($resolved_ip) does not match the known legitimate IP ($known_ip). Possible DNS Spoofing detected!" --title="DNS Spoofing Alert"
    else
        zenity --info --text="No DNS spoofing detected for $domain." --title="Check Complete"
    fi
}

# Main script execution
check_root
check_dns_spoofing
