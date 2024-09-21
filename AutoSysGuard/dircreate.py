import os
import subprocess

# Base directory for the scripts
base_dir = './scripts'
network_dir = os.path.join(base_dir, 'networks')
backup_dir = base_dir

# List of scripts to be created
network_scripts = [
    'arp_spoofing_detection.sh',
    'firewall_config.sh',
    'network_traffic_monitor.sh',
    'port_scan.sh',
    'ssh_hardening.sh',
    'brute_force_detection.sh',
    'intrusion_detection_system.sh',
    'packet_sniffing_detection.sh',
    'dns_spoofing_detection.sh',
    'vpn_configuration_check.sh',
    'network_segmentation_audit.sh',
    'wireless_network_security_check.sh',
    'ip_whitelisting_management.sh',
    'rogue_dhcp_server_detection.sh',
    'mac_address_filtering.sh',
    'ssl_tls_configuration_analyzer.sh',
    'open_ports_vulnerability_scanning.sh'
]

backup_scripts = [
    'backup.sh',
    'secure_backup.sh',
    'security_audit.sh',
    'anomaly_detection.sh',
    'compliance_checker.sh',
    'user_behavior_analytics.sh',
    'setup_ids.sh'
]

# Create base and subdirectories if they don't exist
os.makedirs(network_dir, exist_ok=True)
os.makedirs(backup_dir, exist_ok=True)

# Function to create a script file with a basic structure
def create_script_file(directory, filename):
    script_path = os.path.join(directory, filename)
    if not os.path.exists(script_path):
        with open(script_path, 'w') as file:
            file.write('#!/bin/bash\n\n# TODO: Add script functionality here\n')
        # Make the script executable
        subprocess.run(['chmod', '+x', script_path])
        print(f"Created and set executable: {script_path}")
    else:
        print(f"Script already exists: {script_path}")

# Create network scripts
for script in network_scripts:
    create_script_file(network_dir, script)

# Create backup and other scripts
for script in backup_scripts:
    create_script_file(backup_dir, script)

print("All scripts have been created and updated with executable permissions.")
