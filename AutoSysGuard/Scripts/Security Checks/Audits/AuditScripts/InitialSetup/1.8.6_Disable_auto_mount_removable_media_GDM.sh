#!/usr/bin/env bash
{
    l_pkgoutput="" 
    l_output="" 
    l_output2=""
    l_gpname="local" # Set to desired dconf profile name (default is local)

    # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is Not Applicable
    # Determine system's package manager
    if command -v dpkg-query > /dev/null 2>&1; then
        l_pq="dpkg-query -W"
    elif command -v rpm > /dev/null 2>&1; then
        l_pq="rpm -q"
    fi

    # Check if GDM is installed
    l_pcl="gdm gdm3" # Space separated list of packages to check
    for l_pn in $l_pcl; do
        $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
    done

    echo -e "$l_pkgoutput"

    # Check configuration (If applicable)
    if [ -n "$l_pkgoutput" ]; then
        echo -e "$l_pkgoutput"
        
        # Look for existing settings and set variables if they exist
        l_kfile="$(grep -Prils -- '^\h*automount\b' /etc/dconf/db/*.d)"
        l_kfile2="$(grep -Prils -- '^\h*automount-open\b' /etc/dconf/db/*.d)"
        
        # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
        if [ -f "$l_kfile" ]; then
            l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
        elif [ -f "$l_kfile2" ]; then
            l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile2")"
        fi

        # If the profile name exists, continue checks
        if [ -n "$l_gpname" ]; then
            l_gpdir="/etc/dconf/db/$l_gpname.d"

            # Check if profile file exists
            if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
                l_output="$l_output\n - dconf database profile file \"$(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\" exists"
            else
                l_output2="$l_output2\n - dconf database profile isn't set"
            fi

            # Check if the dconf database file exists
            if [ -f "/etc/dconf/db/$l_gpname" ]; then
                l_output="$l_output\n - The dconf database \"$l_gpname\" exists"
            else
                l_output2="$l_output2\n - The dconf database \"$l_gpname\" doesn't exist"
            fi

            # Check if the dconf database directory exists
            if [ -d "$l_gpdir" ]; then
                l_output="$l_output\n - The dconf directory \"$l_gpdir\" exists"
            else
                l_output2="$l_output2\n - The dconf directory \"$l_gpdir\" doesn't exist"
            fi

            # Check automount setting
            if grep -Pqrs -- '^\h*automount\h*=\h*false\b' "$l_kfile"; then
                l_output="$l_output\n - \"automount\" is set to false in: \"$l_kfile\""
            else
                l_output2="$l_output2\n - \"automount\" is not set correctly"
            fi

            # Check automount-open setting
            if grep -Pqs -- '^\h*automount-open\h*=\h*false\b' "$l_kfile2"; then
                l_output="$l_output\n - \"automount-open\" is set to false in: \"$l_kfile2\""
            else
                l_output2="$l_output2\n - \"automount-open\" is not set correctly"
            fi
        else
            # Settings don't exist. Nothing further to check
            l_output2="$l_output2\n - neither \"automount\" or \"automount-open\" is set"
        fi
    else
        l_output="$l_output\n - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
    fi

    # Report results. If no failures output in l_output2, we pass
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
        [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"

        # Prompt for remediation
        read -p "Do you want to apply the remediation? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            echo "Applying remediation..."

            # Check if GNOME Desktop Manager is installed
            if [ -n "$l_pkgoutput" ]; then
                echo -e "$l_pkgoutput"
                
                # Check configuration (If applicable)
                l_kfile="$(grep -Prils -- '^\h*automount\b' /etc/dconf/db/*.d)"
                l_kfile2="$(grep -Prils -- '^\h*automount-open\b' /etc/dconf/db/*.d)"

                # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
                if [ -f "$l_kfile" ]; then
                    l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
                    echo " - updating dconf profile name to \"$l_gpname\""
                elif [ -f "$l_kfile2" ]; then
                    l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile2")"
                    echo " - updating dconf profile name to \"$l_gpname\""
                fi

                # Check for consistency (Clean up configuration if needed)
                if [ -f "$l_kfile" ] && [ "$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")" != "$l_gpname" ]; then
                    sed -ri "/^\s*automount\s*=/s/^/# /" "$l_kfile"
                    l_kfile="/etc/dconf/db/$l_gpname.d/00-media-automount"
                fi
                if [ -f "$l_kfile2" ] && [ "$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile2")" != "$l_gpname" ]; then
                    sed -ri "/^\s*automount-open\s*=/s/^/# /" "$l_kfile2"
                fi

                [ -z "$l_kfile" ] && l_kfile="/etc/dconf/db/$l_gpname.d/00-media-automount"

                # Check if profile file exists
                if grep -Pq -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*; then
                    echo -e "\n - dconf database profile exists in: \"$(grep -Pl -- "^\h*system-db:$l_gpname\b" /etc/dconf/profile/*)\""
                else
                    [ ! -f "/etc/dconf/profile/user" ] && l_gpfile="/etc/dconf/profile/user" || l_gpfile="/etc/dconf/profile/user2"
                    echo -e " - creating dconf database profile"
                    {
                        echo -e "\nuser-db:user"
                        echo "system-db:$l_gpname"
                    } >> "$l_gpfile"
                fi

                # Create dconf directory if it doesn't exist
                l_gpdir="/etc/dconf/db/$l_gpname.d"
                if [ -d "$l_gpdir" ]; then
                    echo " - The dconf database directory \"$l_gpdir\" exists"
                else
                    echo " - creating dconf database directory \"$l_gpdir\""
                    mkdir "$l_gpdir"
                fi

                # Ensure automount-open setting
                if grep -Pqs -- '^\h*automount-open\h*=\h*false\b' "$l_kfile"; then
                    echo " - \"automount-open\" is set to false in: \"$l_kfile\""
                else
                    echo " - creating \"automount-open\" entry in \"$l_kfile\""
                    echo -e "[org/gnome/desktop/media-handling]\nautomount-open=false" >> "$l_kfile"
                fi

                # Ensure automount setting
                if grep -Pqs -- '^\h*automount\h*=\h*false\b' "$l_kfile"; then
                    echo " - \"automount\" is set to false in: \"$l_kfile\""
                else
                    echo " - creating \"automount\" entry in \"$l_kfile\""
                    echo -e "[org/gnome/desktop/media-handling]\nautomount=false" >> "$l_kfile"
                fi
                
                # Update dconf database
                echo " - updating dconf database..."
                dconf update
                echo "Remediation applied successfully."
            fi
        else
            echo "Remediation not applied."
        fi
    fi

    exit 0
}
