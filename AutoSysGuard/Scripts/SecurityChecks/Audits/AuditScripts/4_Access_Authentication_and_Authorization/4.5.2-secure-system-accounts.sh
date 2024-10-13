#!/usr/bin/env bash
{
    # Variables
    l_output=""
    l_output2=""
    l_valid_shells="^($(awk -F\/ '$NF != \"nologin\" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' -))$"
    a_users=()  # System accounts with valid login shells
    a_ulock=()  # System accounts that are not locked

    # Audit: Check system accounts that have a valid login shell
    while read -r l_user; do
        a_users+=("$l_user")
    done < <(awk -v pat="$l_valid_shells" -F: '($1!~/(root|sync|shutdown|halt|^\+)/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $(NF) ~ pat) { print $1 }' /etc/passwd)

    # Audit: Check system accounts that aren't locked
    while read -r l_ulock; do
        a_ulock+=("$l_ulock")
    done < <(awk -v pat="$l_valid_shells" -F: '($1!~/(root|^\+)/ && $2!~/LK?/ && $3<'"$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)"' && $(NF) ~ pat) { print $1 }' /etc/passwd)

    # Audit Results
    if ! (( ${#a_users[@]} > 0 )); then
        l_output="$l_output\n - Local system accounts have login disabled."
    else
        l_output2="$l_output2\n - There are ${#a_users[@]} system accounts with login enabled.\n - List of accounts:\n$(printf '%s\n' "${a_users[@]}")"
    fi

    if ! (( ${#a_ulock[@]} > 0 )); then
        l_output="$l_output\n - Local system accounts are locked."
    else
        l_output2="$l_output2\n - There are ${#a_ulock[@]} system accounts that are not locked.\n - List of accounts:\n$(printf '%s\n' "${a_ulock[@]}")"
    fi

    # Output results
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n$l_output2"
        [ -n "$l_output" ] && echo -e "\nCorrectly configured accounts:\n$l_output"

        # Ask for remediation
        read -p "Would you like to apply remediation? (y/n): " apply_remed
        if [[ "$apply_remed" == "y" ]]; then
            echo "Applying remediation..."

            # Remediation: Change shell for system accounts with valid login shells to nologin
            for l_user in "${a_users[@]}"; do
                echo " - Changing shell for system account \"$l_user\" to nologin."
                usermod -s "$(which nologin)" "$l_user"
            done

            # Remediation: Lock system accounts that aren't locked
            for l_ulock in "${a_ulock[@]}"; do
                echo " - Locking system account \"$l_ulock\"."
                usermod -L "$l_ulock"
            done

            echo "Remediation completed."
        else
            echo "No remediation applied."
        fi
    fi
}
