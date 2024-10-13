#!/usr/bin/env bash

# Variables for audit
l_pkgoutput=""
l_pq=""
l_pcl="gdm gdm3" # Space-separated list of packages to check
l_idmv="900" # Max value for idle-delay in seconds (1-900)
l_ldmv="5"   # Max value for lock-delay in seconds (0-5)

# Determine the package manager
if command -v dpkg-query > /dev/null 2>&1; then
    l_pq="dpkg-query -W"
elif command -v rpm > /dev/null 2>&1; then
    l_pq="rpm -q"
else
    echo "No supported package manager found."
    exit 1
fi

# Check if GDM is installed
for l_pn in $l_pcl; do
    $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - Checking configuration"
done

# Configuration check only if GDM is installed
if [ -n "$l_pkgoutput" ]; then
    l_output="" l_output2=""
    # Find the key file containing idle-delay configuration
    l_kfile="$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/)"
    if [ -n "$l_kfile" ]; then
        l_profile="$(awk -F'/' '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
        l_pdbdir="/etc/dconf/db/$l_profile.d"
        
        # Check idle-delay value
        l_idv="$(awk -F 'uint32' '/idle-delay/{print $2}' "$l_kfile" | xargs)"
        if [ -n "$l_idv" ]; then
            [ "$l_idv" -gt "0" -a "$l_idv" -le "$l_idmv" ] && l_output="$l_output\n - The \"idle-delay\" option is set to \"$l_idv\" seconds in \"$l_kfile\""
            [ "$l_idv" = "0" ] && l_output2="$l_output2\n - The \"idle-delay\" option is set to \"$l_idv\" (disabled) in \"$l_kfile\""
            [ "$l_idv" -gt "$l_idmv" ] && l_output2="$l_output2\n - The \"idle-delay\" option is set to \"$l_idv\" seconds (greater than $l_idmv) in \"$l_kfile\""
        else
            l_output2="$l_output2\n - The \"idle-delay\" option is not set in \"$l_kfile\""
        fi

        # Check lock-delay value
        l_ldv="$(awk -F 'uint32' '/lock-delay/{print $2}' "$l_kfile" | xargs)"
        if [ -n "$l_ldv" ]; then
            [ "$l_ldv" -ge "0" -a "$l_ldv" -le "$l_ldmv" ] && l_output="$l_output\n - The \"lock-delay\" option is set to \"$l_ldv\" seconds in \"$l_kfile\""
            [ "$l_ldv" -gt "$l_ldmv" ] && l_output2="$l_output2\n - The \"lock-delay\" option is set to \"$l_ldv\" seconds (greater than $l_ldmv) in \"$l_kfile\""
        else
            l_output2="$l_output2\n - The \"lock-delay\" option is not set in \"$l_kfile\""
        fi

        # Confirm dconf profile existence
        if grep -Psq "^\h*system-db:$l_profile" /etc/dconf/profile/*; then
            l_output="$l_output\n - The \"$l_profile\" profile exists"
        else
            l_output2="$l_output2\n - The \"$l_profile\" profile doesn't exist"
        fi

        # Confirm dconf database file existence
        if [ -f "/etc/dconf/db/$l_profile" ]; then
            l_output="$l_output\n - The \"$l_profile\" profile exists in the dconf database"
        else
            l_output2="$l_output2\n - The \"$l_profile\" profile doesn't exist in the dconf database"
        fi
    else
        l_output2="$l_output2\n - The \"idle-delay\" option doesn't exist, remaining tests skipped"
    fi
else
    l_output="$l_output\n - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
fi

# Report results
if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
    
    # Prompt for remediation
    read -p "Do you want to apply remediation to fix the issues? (y/n): " user_input
    if [[ "$user_input" == "y" ]]; then
        # Remediation: Create or edit dconf profile and key file
        echo "Applying remediation..."

        # Create dconf profile
        mkdir -p /etc/dconf/db/local.d
        echo -e '\nuser-db:user\nsystem-db:local' > /etc/dconf/profile/user

        # Create the key file with the correct settings
        l_key_file="/etc/dconf/db/local.d/00-screensaver"
        {
            echo '# Specify the dconf path'
            echo '[org/gnome/desktop/session]'
            echo ''
            echo '# Number of seconds of inactivity before the screen goes blank'
            echo "idle-delay=uint32 $l_idmv"
            echo ''
            echo '# Specify the dconf path'
            echo '[org/gnome/desktop/screensaver]'
            echo ''
            echo '# Number of seconds after the screen is blank before locking the screen'
            echo "lock-delay=uint32 $l_ldmv"
        } > "$l_key_file"
        
        # Update the system databases
        dconf update
        echo "Remediation complete. Please log out and back in for changes to take effect."
    else
        echo "No changes made. Please address the issues manually."
    fi
fi
