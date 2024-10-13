#!/usr/bin/env bash

# Function to perform audit
perform_audit() {
    l_output=""
    l_output2=""
    a_arr=(); a_suid=(); a_sgid=() # initialize arrays

    # Populate array with files that will possibly fail one of the audits
    while read -r l_mpname; do
        while IFS= read -r -d $'\0' l_file; do
            [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
        done < <(find "$l_mpname" -xdev -not -path "/run/user/*" -type f \( -perm -2000 -o -perm -4000 \) -print0)
    done <<< "$(findmnt -Derno target)"

    # Test files in the array
    while IFS="^" read -r l_fname l_mode; do
        if [ -f "$l_fname" ]; then
            l_suid_mask="04000"; l_sgid_mask="02000"
            [ $(( $l_mode & $l_suid_mask )) -gt 0 ] && a_suid+=("$l_fname")
            [ $(( $l_mode & $l_sgid_mask )) -gt 0 ] && a_sgid+=("$l_fname")
        fi
    done <<< "$(printf '%s\n' "${a_arr[@]}")"

    if ! (( ${#a_suid[@]} > 0 )); then
        l_output="$l_output\n - There are no SUID files exist on the system"
    else
        l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_suid[@]}")\" SUID executable files:\n$(printf '%s\n' "${a_suid[@]}")\n - end of list -\n"
    fi

    if ! (( ${#a_sgid[@]} > 0 )); then
        l_output="$l_output\n - There are no SGID files exist on the system"
    else
        l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_sgid[@]}")\" SGID executable files:\n$(printf '%s\n' "${a_sgid[@]}")\n - end of list -\n"
    fi

    [ -n "$l_output2" ] && l_output2="$l_output2\n- Review the preceding list(s) of SUID and/or SGID files to\n- ensure that no rogue programs have been introduced onto the system.\n"
    unset a_arr; unset a_suid; unset a_sgid # Remove arrays

    # If l_output2 is empty, Nothing to report
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n$l_output2\n"
        [ -n "$l_output" ] && echo -e "$l_output\n"
    fi
}

# Function to perform remediation
perform_remediation() {
    echo "Performing remediation for SUID and SGID files..."

    # Loop through the SUID files and reset permissions to remove SUID bit
    for file in "${a_suid[@]}"; do
        if [ -f "$file" ]; then
            echo "Removing SUID bit from $file"
            chmod u-s "$file"
        fi
    done

    # Loop through the SGID files and reset permissions to remove SGID bit
    for file in "${a_sgid[@]}"; do
        if [ -f "$file" ]; then
            echo "Removing SGID bit from $file"
            chmod g-s "$file"
        fi
    done

    echo "Remediation completed."
}

# Main script execution
perform_audit

# Check if there are any SUID or SGID files found and ask for remediation
if [[ ${#a_suid[@]} -gt 0 || ${#a_sgid[@]} -gt 0 ]]; then
    read -p "Do you want to apply remediation for SUID and SGID files? (y/n): " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        perform_remediation
    else
        echo "No remediation applied."
    fi
else
    echo "No SUID or SGID files found that require remediation."
fi
