#!/usr/bin/env bash

{
  l_output=""
  l_output2=""
  a_path=()
  a_arr=()
  a_nouser=()
  a_nogroup=() # Initialize arrays

  # Set paths to exclude from the search
  a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*")
  
  # Exclude mounted filesystems
  while read -r l_bfs; do
    a_path+=( -a ! -path "$l_bfs/*" )
  done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')

  # Find files and directories with no owner or no group
  while IFS= read -r -d $'\0' l_file; do
    [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%U^%G' "$l_file")") && echo "Adding: $l_file"
  done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2> /dev/null)

  # Check for unowned and ungrouped files
  while IFS="^" read -r l_fname l_user l_group; do
    [ "$l_user" = "UNKNOWN" ] && a_nouser+=("$l_fname")
    [ "$l_group" = "UNKNOWN" ] && a_nogroup+=("$l_fname")
  done <<< "$(printf '%s\n' "${a_arr[@]}")"

  if ! (( ${#a_nouser[@]} > 0 )); then
    l_output="$l_output\n - No unowned files or directories exist on the local filesystem."
  else
    l_output2="$l_output2\n - There are \"$(printf '%s' "${#a_nouser[@]}")\" unowned files or directories on the system.\n - The following is a list of unowned files and/or directories:\n$(printf '%s\n' "${a_nouser[@]}")\n - end of list"
  fi

  if ! (( ${#a_nogroup[@]} > 0 )); then
    l_output="$l_output\n - No ungrouped files or directories exist on the local filesystem."
  else
    l_output2="$l_output2\n - There are \"$(printf '%s' "${#a_nogroup[@]}")\" ungrouped files or directories on the system.\n - The following is a list of ungrouped files and/or directories:\n$(printf '%s\n' "${a_nogroup[@]}")\n - end of list"
  fi

  # Remove arrays
  unset a_path; unset a_arr; unset a_nouser; unset a_nogroup 

  # Audit result output
  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - * Correctly configured *:\n$l_output\n"
  else
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :\n$l_output2"
    [ -n "$l_output" ] && echo -e "\n- * Correctly configured *:\n$l_output\n"

    # Ask user for remediation
    read -p "Do you want to change ownership of unowned files to a specific user? (y/n): " response
    if [[ "$response" == "y" ]]; then
      read -p "Enter the username to assign ownership: " username
      for file in "${a_nouser[@]}"; do
        echo "Changing ownership of $file to $username..."
        chown "$username" "$file" 2> /dev/null
      done
    fi

    read -p "Do you want to remove unowned files? (y/n): " response_remove
    if [[ "$response_remove" == "y" ]]; then
      for file in "${a_nouser[@]}"; do
        echo "Removing $file..."
        rm -rf "$file" 2> /dev/null
      done
    fi
  fi
}
