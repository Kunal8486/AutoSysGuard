#!/usr/bin/env bash

# Initialize variables for output
l_output=""
l_output2=""
l_heout2=""
l_hoout2=""
l_haout2=""

# Get valid shells
l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -r 's,/,\\\\/,g;p' | paste -s -d '|'))$"

# Clear and initialize array
unset a_uarr && a_uarr=()

# Populate array with users and user home location
while read -r l_epu l_eph; do
    a_uarr+=("$l_epu $l_eph")
done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)"

# Get the number of users found
l_asize="${#a_uarr[@]}"
[ "$l_asize" -gt "10000" ] && echo -e "\n ** INFO **\n - \"$l_asize\" Local interactive users found on the system\n - This may be a long-running check\n"

# Audit user home directories
while read -r l_user l_home; do
    if [ -d "$l_home" ]; then
        l_mask='0027'
        l_max="$(printf '%o' $((0777 & ~$l_mask)))"
        while read -r l_own l_mode; do
            [ "$l_user" != "$l_own" ] && l_hoout2="$l_hoout2\n - User: \"$l_user\" Home \"$l_home\" is owned by: \"$l_own\""
            if [ $((l_mode & l_mask)) -gt 0 ]; then
                l_haout2="$l_haout2\n - User: \"$l_user\" Home \"$l_home\" is mode: \"$l_mode\" should be mode: \"$l_max\" or more restrictive"
            fi
        done <<< "$(stat -Lc '%U %#a' "$l_home")"
    else
        l_heout2="$l_heout2\n - User: \"$l_user\" Home \"$l_home\" Doesn't exist"
    fi
done <<< "$(printf '%s\n' "${a_uarr[@]}")"

# Prepare output based on audit results
[ -z "$l_heout2" ] && l_output="$l_output\n - home directories exist" || l_output2="$l_output2$l_heout2"
[ -z "$l_hoout2" ] && l_output="$l_output\n - own their home directory" || l_output2="$l_output2$l_hoout2"
[ -z "$l_haout2" ] && l_output="$l_output\n - home directories are mode: \"$l_max\" or more restrictive" || l_output2="$l_output2$l_haout2"

# Final audit result output
if [ -n "$l_output" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n - * Correctly configured * :\n$l_output"
fi

if [ -n "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :\n$l_output2"

    # Prompt for remediation
    read -p "Do you want to remediate the issues? (y/n): " choice
    if [[ "$choice" == "y" ]]; then
        for user_home in "${a_uarr[@]}"; do
            IFS=' ' read -r l_user l_home <<< "$user_home"
            if [ ! -d "$l_home" ]; then
                echo -e "\n - User: \"$l_user\" Home \"$l_home\" Doesn't exist."
                read -p "Do you want to create the home directory for \"$l_user\"? (y/n): " create_choice
                if [[ "$create_choice" == "y" ]]; then
                    mkdir -p "$l_home"
                    chown "$l_user:$l_user" "$l_home"
                    echo "Home directory for \"$l_user\" created and ownership set."
                fi
            else
                # Check permissions
                l_mode=$(stat -c '%a' "$l_home")
                if [ $((l_mode & 0o027)) -gt 0 ]; then
                    echo "Removing excess permissions from \"$l_home\"."
                    chmod g-w,o-rwx "$l_home"
                    echo "Excess permissions removed from \"$l_home\"."
                fi

                # Check ownership
                l_owner=$(stat -c '%U' "$l_home")
                if [ "$l_owner" != "$l_user" ]; then
                    echo "Changing ownership of \"$l_home\" to \"$l_user\"."
                    chown "$l_user:$l_user" "$l_home"
                    echo "Ownership of \"$l_home\" changed to \"$l_user\"."
                fi
            fi
        done
    else
        echo "No remediation actions were taken."
    fi
fi
