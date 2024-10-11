#!/usr/bin/env bash

# Function to audit world writable files and directories
audit_world_writable() {
    local l_smask='01000'
    local a_path=() a_arr=() a_file=() a_dir=() # Initialize arrays

    # Exclude specific paths
    a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "/sys/kernel/security/apparmor/*" -a ! -path "/snap/*" -a ! -path "/sys/fs/cgroup/memory/*")

    # Gather filesystems
    while read -r l_bfs; do
        a_path+=( -a ! -path "$l_bfs/*")
    done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/{print $2}')

    # Populate array with world writable files and directories
    while IFS= read -r -d $'\0' l_file; do
        [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
    done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)

    # Test files and directories in the array
    while IFS="^" read -r l_fname l_mode; do
        if [ -f "$l_fname" ]; then
            a_file+=("$l_fname") # Add world writable files
        fi
        if [ -d "$l_fname" ]; then
            [ ! $(( l_mode & l_smask )) -gt 0 ] && a_dir+=("$l_fname") # Add directories without sticky bit
        fi
    done < <(printf '%s\n' "${a_arr[@]}")

    # Report results
    if (( ${#a_file[@]} > 0 )); then
        echo -e "\n** World Writable Files Found **"
        for file in "${a_file[@]}"; do
            echo " - $file"
        done
    else
        echo -e "\n- No world writable files exist on the local filesystem."
    fi

    if (( ${#a_dir[@]} > 0 )); then
        echo -e "\n** World Writable Directories Without Sticky Bit Found **"
        for dir in "${a_dir[@]}"; do
            echo " - $dir"
        done
    else
        echo -e "\n- All world writable directories have the sticky bit set."
    fi
}

# Function to remediate world writable files and directories
remediate_world_writable() {
    local l_smask='01000'
    local a_path=() a_arr=() # Initialize array

    # Exclude specific paths
    a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "/sys/kernel/security/apparmor/*" -a ! -path "/snap/*" -a ! -path "/sys/fs/cgroup/memory/*")

    # Gather filesystems
    while read -r l_bfs; do
        a_path+=( -a ! -path "$l_bfs/*")
    done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/{print $2}')

    # Populate array with world writable files and directories
    while IFS= read -r -d $'\0' l_file; do
        [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
    done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)

    # Test files and directories in the array and apply remediation
    while IFS="^" read -r l_fname l_mode; do
        if [ -f "$l_fname" ]; then
            echo "Removing write permission from 'other' for: $l_fname"
            chmod o-w "$l_fname"
        fi
        if [ -d "$l_fname" ]; then
            if [ ! $(( l_mode & l_smask )) -gt 0 ]; then
                echo "Adding sticky bit to directory: $l_fname"
                chmod a+t "$l_fname"
            fi
        fi
    done < <(printf '%s\n' "${a_arr[@]}")
}

# Main script execution
echo "Auditing world writable files and directories..."
audit_world_writable

read -p "Do you want to remediate the findings (y/n)? " choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Remediating..."
    remediate_world_writable
    echo "Remediation complete."
else
    echo "No changes were made."
fi
