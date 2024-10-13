#!/usr/bin/env bash

audit_and_remediate_ssh_keys() {
    l_output="" l_output2=""
    l_skgn="ssh_keys" # Group designated to own openSSH keys
    l_skgid="$(awk -F: '($1 == "'"$l_skgn"'"){print $3}' /etc/group)" # Get GID of group
    [ -n "$l_skgid" ] && l_agroup="(root|$l_skgn)" || l_agroup="root"

    # Clear and initialize array
    unset a_skarr && a_skarr=()

    # Find all OpenSSH private key files
    while IFS= read -r -d $'\0' l_file; do
        if grep -Pq ':\h+OpenSSH\h+private\h+key\b' <<< "$(file "$l_file")"; then
            a_skarr+=("$(stat -Lc '%n^%#a^%U^%G^%g' "$l_file")")
        fi
    done < <(find -L /etc/ssh -xdev -type f -print0)

    # Loop through each private key file found and audit them
    while IFS="^" read -r l_file l_mode l_owner l_group l_gid; do
        echo "File: \"$l_file\" Mode: \"$l_mode\" Owner: \"$l_owner\" Group: \"$l_group\" GID: \"$l_gid\""
        l_out2=""
        [ "$l_gid" = "$l_skgid" ] && l_pmask="0137" || l_pmask="0177"
        l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"

        # Check for correct mode
        if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
            l_out2="$l_out2\n - Mode: \"$l_mode\" should be mode: \"$l_maxperm\" or more restrictive"
        fi

        # Check for correct ownership
        if [ "$l_owner" != "root" ]; then
            l_out2="$l_out2\n - Owned by: \"$l_owner\" should be owned by \"root\""
        fi

        # Check for correct group ownership
        if [[ ! "$l_group" =~ $l_agroup ]]; then
            l_out2="$l_out2\n - Owned by group \"$l_group\" should be group owned by: \"${l_agroup//|/ or }\""
        fi

        if [ -n "$l_out2" ]; then
            l_output2="$l_output2\n - File: \"$l_file\"$l_out2"
        else
            l_output="$l_output\n - File: \"$l_file\"\n - Correct: mode ($l_mode), owner ($l_owner), and group owner ($l_group) configured"
        fi
    done <<< "$(printf '%s\n' "${a_skarr[@]}")"

    # Display audit result
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n *** PASS ***\n- * Correctly set * :\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n"
        [ -n "$l_output" ] && echo -e " - * Correctly set * :\n$l_output\n"
        remediate_ssh_keys
    fi
}

remediate_ssh_keys() {
    read -p "Would you like to apply remediation? (y/n): " apply_remediation
    if [[ "$apply_remediation" == "y" || "$apply_remediation" == "Y" ]]; then
        echo "Applying remediation..."
        l_skgn="ssh_keys" # Group designated to own openSSH keys
        l_skgid="$(awk -F: '($1 == "'"$l_skgn"'"){print $3}' /etc/group)" # Get GID of group

        if [ -n "$l_skgid" ]; then
            l_agroup="(root|$l_skgn)" && l_sgroup="$l_skgn" && l_mfix="u-x,g-wx,o-rwx"
        else
            l_agroup="root" && l_sgroup="root" && l_mfix="u-x,go-rwx"
        fi

        # Clear and initialize array
        unset a_skarr && a_skarr=()

        # Find all OpenSSH private key files
        while IFS= read -r -d $'\0' l_file; do
            if grep -Pq ':\h+OpenSSH\h+private\h+key\b' <<< "$(file "$l_file")"; then
                a_skarr+=("$(stat -Lc '%n^%#a^%U^%G^%g' "$l_file")")
            fi
        done < <(find -L /etc/ssh -xdev -type f -print0)

        # Loop through each private key file and apply remediation
        while IFS="^" read -r l_file l_mode l_owner l_group l_gid; do
            l_out2=""
            [ "$l_gid" = "$l_skgid" ] && l_pmask="0137" || l_pmask="0177"
            l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"

            # Fix permissions
            if [ $(( $l_mode & $l_pmask )) -gt 0 ]; then
                echo " - Correcting permissions on $l_file"
                chmod "$l_mfix" "$l_file"
            fi

            # Fix ownership
            if [ "$l_owner" != "root" ]; then
                echo " - Changing owner to root for $l_file"
                chown root "$l_file"
            fi

            # Fix group ownership
            if [[ ! "$l_group" =~ $l_agroup ]]; then
                echo " - Changing group ownership to $l_sgroup for $l_file"
                chgrp "$l_sgroup" "$l_file"
            fi
        done <<< "$(printf '%s\n' "${a_skarr[@]}")"

        echo "Remediation applied successfully."
    else
        echo "Remediation skipped."
    fi
}

# Run the audit and remediation process
audit_and_remediate_ssh_keys
