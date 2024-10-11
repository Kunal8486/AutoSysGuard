#!/usr/bin/env bash

{
  l_output=""
  l_output2=""
  a_arr=()
  a_suid=()
  a_sgid=() # Initialize arrays

  # Populate array with files that are SUID or SGID
  while read -r l_mpname; do
    while IFS= read -r -d $'\0' l_file; do
      [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
    done < <(find "$l_mpname" -xdev -not -path "/run/user/*" -type f \( -perm -2000 -o -perm -4000 \) -print0)
  done <<< "$(findmnt -Derno target)"

  # Test files in the array for SUID and SGID
  while IFS="^" read -r l_fname l_mode; do
    if [ -f "$l_fname" ]; then
      l_suid_mask="04000"
      l_sgid_mask="02000"
      [ $(( $l_mode & $l_suid_mask )) -gt 0 ] && a_suid+=("$l_fname")
      [ $(( $l_mode & $l_sgid_mask )) -gt 0 ] && a_sgid+=("$l_fname")
    fi
  done <<< "$(printf '%s\n' "${a_arr[@]}")"

  # Prepare output messages for SUID and SGID files
  if ! (( ${#a_suid[@]} > 0 )); then
    l_output="$l_output\n - There are no SUID files on the system."
  else
    l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_suid[@]}")\" SUID executable files:\n$(printf '%s\n' "${a_suid[@]}")\n - end of list -\n"
  fi

  if ! (( ${#a_sgid[@]} > 0 )); then
    l_output="$l_output"\n - There are no SGID files on the system."
  else
    l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_sgid[@]}")\" SGID executable files:\n$(printf '%s\n' "${a_sgid[@]}")\n - end of list -\n"
  fi

  # Additional output for review
  [ -n "$l_output2" ] && l_output2="$l_output2\n- Review the preceding list(s) of SUID and/or SGID files to ensure that no rogue programs have been introduced onto the system.\n"
  
  # Remove arrays
  unset a_arr; unset a_suid; unset a_sgid 

  # If l_output2 is empty, nothing to report
  if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n$l_output\n"
  else
    echo -e "\n- Audit Result:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "$l_output\n"
  fi

  # Prompt for further action
  read -p "Would you like to review the listed files for integrity? (y/n): " review_response
  if [[ "$review_response" == "y" ]]; then
    echo "Please verify the integrity of the following SUID files:"
    for file in "${a_suid[@]}"; do
      echo "$file"
    done

    echo "Please verify the integrity of the following SGID files:"
    for file in "${a_sgid[@]}"; do
      echo "$file"
    done
  fi
}
