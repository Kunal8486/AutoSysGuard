import os

# Base directory for the main audit
base_dir = "Initial_Setup"

# Function to create folder structure and scripts
def create_folders_and_scripts(base, structure):
    for key, value in structure.items():
        folder_path = os.path.join(base, key)
        os.makedirs(folder_path, exist_ok=True)
        
        # If it's a dictionary, we have subfolders to process
        if isinstance(value, dict):
            create_folders_and_scripts(folder_path, value)
        # Otherwise, it's a list of scripts to create
        else:
            for script in value:
                script_path = os.path.join(folder_path, script + ".sh")
                with open(script_path, "w") as script_file:
                    script_file.write("#!/bin/bash\n")
                    script_file.write(f"# Script for {script}\n")
                print(f"Created: {script_path}")

# Define the folder structure and scripts
structure = {
    "1.1 Filesystem Configuration": {
        "1.1.1 Disable unused filesystems": {
            "1.1.1.1 Ensure mounting of cramfs filesystems is disabled (Automated)": [],
            "1.1.1.2 Ensure mounting of freevxfs filesystems is disabled (Automated)": [],
            "1.1.1.3 Ensure mounting of jffs2 filesystems is disabled (Automated)": [],
            "1.1.1.4 Ensure mounting of hfs filesystems is disabled (Automated)": [],
            "1.1.1.5 Ensure mounting of hfsplus filesystems is disabled (Automated)": [],
            "1.1.1.6 Ensure mounting of squashfs filesystems is disabled (Automated)": [],
            "1.1.1.7 Ensure mounting of udf filesystems is disabled (Automated)": []
        },
        "1.1.2 Configure /tmp": {
            "1.1.2.1 Ensure /tmp is a separate partition (Automated)": [],
            "1.1.2.2 Ensure nodev option set on /tmp partition (Automated)": [],
            "1.1.2.3 Ensure noexec option set on /tmp partition (Automated)": [],
            "1.1.2.4 Ensure nosuid option set on /tmp partition (Automated)": []
        },
        "1.1.3 Configure /var": {
            "1.1.3.1 Ensure separate partition exists for /var (Automated)": [],
            "1.1.3.2 Ensure nodev option set on /var partition (Automated)": [],
            "1.1.3.3 Ensure nosuid option set on /var partition (Automated)": []
        },
        "1.1.4 Configure /var/tmp": {
            "1.1.4.1 Ensure separate partition exists for /var/tmp (Automated)": [],
            "1.1.4.2 Ensure nodev option set on /var/tmp partition (Automated)": [],
            "1.1.4.3 Ensure noexec option set on /var/tmp partition (Automated)": [],
            "1.1.4.4 Ensure nosuid option set on /var/tmp partition (Automated)": []
        },
        "1.1.5 Configure /var/log": {
            "1.1.5.1 Ensure separate partition exists for /var/log (Automated)": [],
            "1.1.5.2 Ensure nodev option set on /var/log partition (Automated)": [],
            "1.1.5.3 Ensure noexec option set on /var/log partition (Automated)": [],
            "1.1.5.4 Ensure nosuid option set on /var/log partition (Automated)": []
        },
        "1.1.6 Configure /var/log/audit": {
            "1.1.6.1 Ensure separate partition exists for /var/log/audit (Automated)": [],
            "1.1.6.2 Ensure nodev option set on /var/log/audit partition (Automated)": [],
            "1.1.6.3 Ensure noexec option set on /var/log/audit partition (Automated)": [],
            "1.1.6.4 Ensure nosuid option set on /var/log/audit partition (Automated)": []
        },
        "1.1.7 Configure /home": {
            "1.1.7.1 Ensure separate partition exists for /home (Automated)": [],
            "1.1.7.2 Ensure nodev option set on /home partition (Automated)": [],
            "1.1.7.3 Ensure nosuid option set on /home partition (Automated)": []
        },
        "1.1.8 Configure /dev/shm": {
            "1.1.8.1 Ensure nodev option set on /dev/shm partition (Automated)": [],
            "1.1.8.2 Ensure noexec option set on /dev/shm partition (Automated)": [],
            "1.1.8.3 Ensure nosuid option set on /dev/shm partition (Automated)": []
        },
        "1.1.9 Disable Automounting (Automated)": [],
        "1.1.10 Disable USB Storage (Automated)": []
    },
    "1.2 Filesystem Integrity Checking": {
        "1.2.1 Ensure AIDE is installed (Automated)": [],
        "1.2.2 Ensure filesystem integrity is regularly checked (Automated)": []
    },
    "1.3 Configure Software and Patch Management": {
        "1.3.1 Ensure updates, patches, and additional security software are installed (Manual)": [],
        "1.3.2 Ensure package manager repositories are configured (Manual)": [],
        "1.3.3 Ensure GPG keys are configured (Manual)": []
    },
    # Add other categories similarly
}

# Create folders and scripts based on the structure
create_folders_and_scripts(base_dir, structure)

print("Audit directories and scripts setup completed.")
