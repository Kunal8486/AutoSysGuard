#!/usr/bin/env bash

# Function to check file access permissions
file_access_chk() {
    local l_hdfile="$1"
    local l_mode="$2"
    local l_owner="$3"
    local l_gowner="$4"
    local l_user="$5"
    local l_group="$6"
    local l_mask="$7"
    local l_facout2=""

    local l_max="$(printf '%o' $((0777 & ~$l_mask)) )"

    if [ $((l_mode & l_mask)) -gt 0 ]; then
        l_facout2="$l_facout2\n - File: \"$l_hdfile\" is mode: \"$l_mode\" and should be mode: \"$l_max\" or more restrictive"
    fi
    if [[ ! "$l_owner" =~ ($l_user) ]]; then
        l_facout2="$l_facout2\n - File: \"$l_hdfile\" owned by: \"$l_owner\" and should be owned by \"$l_user\""
    fi
    if [[ ! "$l_gowner" =~ ($l_group) ]]; then
        l_facout2="$l_facout2\n - File: \"$l_hdfile\" group owned by: \"$l_gowner\" and should be group owned by \"$l_group\""
    fi
    echo -e "$l_facout2"
}

# Function to fix file access permissions
file_access_fix() {
    local l_hdfile="$1"
    local l_user="$2"
    local l_group="$3"
    local l_mode="$4"
    local l_owner="$5"
    local l_gowner="$6"
    local l_mask="$7"

    local l_max="$(printf '%o' $((0777 & ~$l_mask)) )"
    local l_chp

    if [ $((l_mode & l_mask)) -gt 0 ]; then
        l_chp="u-x,go-rwx"
        echo -e " - File: \"$l_hdfile\" is mode: \"$l_mode\" and should be mode: \"$l_max\" or more restrictive."
        read -p "Do you want to change the mode of \"$l_hdfile\" to \"$l_max\"? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            chmod "$l_max" "$l_hdfile"
            echo " - Changed mode to \"$l_max\"."
        fi
    fi

    if [[ ! "$l_owner" =~ ($l_user) ]]; then
        echo -e " - File: \"$l_hdfile\" owned by: \"$l_owner\" and should be owned by \"$l_user\"."
        read -p "Do you want to change ownership of \"$l_hdfile\" to \"$l_user\"? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            chown "$l_user" "$l_hdfile"
            echo " - Changed ownership to \"$l_user\"."
        fi
    fi

    if [[ ! "$l_gowner" =~ ($l_group) ]]; then
        echo -e " - File: \"$l_hdfile\" group owned by: \"$l_gowner\" and should be group owned by \"$l_group\"."
        read -p "Do you want to change group ownership of \"$l_hdfile\" to \"$l_group\"? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            chgrp "$l_group" "$l_hdfile"
            echo " - Changed group ownership to \"$l_group\"."
        fi
    fi
}

# Main script execution starts here
{
    l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|'))$"
    unset a_uarr
    a_uarr=()

    # Populate array with users and home directory locations
    while read -r l_epu l_eph; do
        [[ -n "$l_epu" && -n "$l_eph" ]] && a_uarr+=("$l_epu $l_eph")
    done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)"

    for user_home in "${a_uarr[@]}"; do
        l_user=$(echo "$user_home" | awk '{print $1}')
        l_home=$(echo "$user_home" | awk '{print $2}')

        if [ -d "$l_home" ]; then
            echo -e "\n - Checking user: \"$l_user\" home directory: \"$l_home\""
            l_group="$(id -gn "$l_user" | xargs)"
            l_group="${l_group// /|}"

            while IFS= read -r -d $'\0' l_hdfile; do
                while read -r l_mode l_owner l_gowner; do
                    case "$(basename "$l_hdfile")" in
                        .forward | .rhost )
                            echo -e " - File: \"$l_hdfile\" exists.\n - Please investigate and manually delete \"$l_hdfile\"."
                            ;;
                        .netrc )
                            l_mask='0177'
                            l_facout2=$(file_access_chk "$l_hdfile" "$l_mode" "$l_owner" "$l_gowner" "$l_user" "$l_group" "$l_mask")
                            echo -e "$l_facout2"
                            if [ -n "$l_facout2" ]; then
                                file_access_fix "$l_hdfile" "$l_user" "$l_group" "$l_mode" "$l_owner" "$l_gowner" "$l_mask"
                            fi
                            ;;
                        .bash_history )
                            l_mask='0177'
                            l_facout2=$(file_access_chk "$l_hdfile" "$l_mode" "$l_owner" "$l_gowner" "$l_user" "$l_group" "$l_mask")
                            echo -e "$l_facout2"
                            if [ -n "$l_facout2" ]; then
                                file_access_fix "$l_hdfile" "$l_user" "$l_group" "$l_mode" "$l_owner" "$l_gowner" "$l_mask"
                            fi
                            ;;
                        * )
                            l_mask='0133'
                            l_facout2=$(file_access_chk "$l_hdfile" "$l_mode" "$l_owner" "$l_gowner" "$l_user" "$l_group" "$l_mask")
                            echo -e "$l_facout2"
                            if [ -n "$l_facout2" ]; then
                                file_access_fix "$l_hdfile" "$l_user" "$l_group" "$l_mode" "$l_owner" "$l_gowner" "$l_mask"
                            fi
                            ;;
                    esac
                done <<< "$(stat -Lc '%#a %U %G' "$l_hdfile")"
            done < <(find "$l_home" -xdev -type f -name '.*' -print0)
        fi
    done
}
