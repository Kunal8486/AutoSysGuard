#!/usr/bin/env bash
{
    l_output=""
    l_output2=""
    l_tmv_max="900"
    l_searchloc="/etc/bashrc /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh"
    a_tmofile=()

    # Audit
    while read -r l_file; do
        [ -e "$l_file" ] && a_tmofile+=("$(readlink -f "$l_file")")
    done < <(grep -PRils '^\h*([^#\n\r]+\h+)?TMOUT=\d+\b' $l_searchloc)

    if ! (( ${#a_tmofile[@]} > 0 )); then
        l_output2="$l_output2\n - TMOUT is not set"
    elif (( ${#a_tmofile[@]} > 1 )); then
        l_output2="$l_output2\n - TMOUT is set in multiple locations.\n - List of files where TMOUT is set:\n$(printf '%s\n' "${a_tmofile[@]}")\n - end of list\n"
    else
        for l_file in "${a_tmofile[@]}"; do
            if (( "$(grep -Pci '^\h*([^#\n\r]+\h+)?TMOUT=\d+' "$l_file")" > 1 )); then
                l_output2="$l_output2\n - TMOUT is set multiple times in \"$l_file\""
            else
                l_tmv="$(grep -Pi '^\h*([^#\n\r]+\h+)?TMOUT=\d+' "$l_file" | grep -Po '\d+')"
                if (( "$l_tmv" > "$l_tmv_max" || "$l_tmv" == "0" )); then
                    l_output2="$l_output\n - TMOUT is \"$l_tmv\" in \"$l_file\"\n - Should be \"$l_tmv_max\" or less and not \"0\""
                else
                    l_output="$l_output\n- TMOUT is correctly set to \"$l_tmv\" in \"$l_file\""
                    if grep -Piq '^\h*([^#\n\r]+\h+)?readonly\h+TMOUT\b' "$l_file"; then
                        l_output="$l_output\n- TMOUT is correctly set to \"readonly\" in \"$l_file\""
                    else
                        l_output2="$l_output2\n- TMOUT is not set to \"readonly\""
                    fi
                    if grep -Piq '^(\h*|\h*[^#\n\r]+\h*;\h*)export\h+TMOUT\b' "$l_file"; then
                        l_output="$l_output\n- TMOUT is correctly set to \"export\" in \"$l_file\""
                    else
                        l_output2="$l_output2\n- TMOUT is not set to \"export\""
                    fi
                fi
            fi
        done
    fi

    unset a_tmofile # Remove array

    # Output result
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n - * Correctly configured * :\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - * Reasons for audit failure * :\n$l_output2"
        [ -n "$l_output" ] && echo -e "- * Correctly configured * :\n$l_output\n"

        # Ask for remediation
        read -p "Would you like to apply remediation? (y/n): " apply_remed
        if [[ "$apply_remed" == "y" ]]; then
            # Remediation
            echo "Applying remediation..."
            # Remove TMOUT from all locations
            sed -i '/TMOUT/d' /etc/bashrc /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh 2>/dev/null

            # Apply correct TMOUT configuration
            echo "readonly TMOUT=900 ; export TMOUT" >> /etc/profile.d/tmout.sh

            echo "Remediation applied. TMOUT set to 900, readonly, and exported in /etc/profile.d/tmout.sh."
        else
            echo "No remediation applied."
        fi
    fi
}
