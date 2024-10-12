#!/usr/bin/env bash
{
    l_pkgoutput="" l_output="" l_output2=""
    
    # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is Not Applicable
    # determine system's package manager
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

    # Check configuration (If applicable)
    if [ -n "$l_pkgoutput" ]; then
        echo -e "$l_pkgoutput"
        
        # Look for existing settings and set variables if they exist
        l_kfile="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d)"
        
        # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
        if [ -f "$l_kfile" ]; then
            l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
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
            
            # Check autorun-never setting
            if grep -Pqrs -- '^\h*autorun-never\h*=\h*true\b' "$l_kfile"; then
                l_output="$l_output\n - \"autorun-never\" is set to true in: \"$l_kfile\""
            else
                l_output2="$l_output2\n - \"autorun-never\" is not set correctly"
            fi
        else
            # Settings don't exist. Nothing further to check
            l_output2="$l_output2\n - \"autorun-never\" is not set"
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

        # Prompt user for remediation
        read -p "Do you want to apply the remediation? (y/n): " apply_remediation
        if [[ "$apply_remediation" == "y" ]]; then
            # Remedial actions start here
            l_gpname="local" # Set to desired dconf profile name (default is local)
            
            # Check if GDM is installed
            for l_pn in $l_pcl; do
                $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
            done
            
            echo -e "$l_pkgoutput"
            
            # Check configuration (If applicable)
            if [ -n "$l_pkgoutput" ]; then
                echo -e "$l_pkgoutput"
                
                # Look for existing settings and set variables if they exist
                l_kfile="$(grep -Prils -- '^\h*autorun-never\b' /etc/dconf/db/*.d)"
                
                # Set profile name based on dconf db directory ({PROFILE_NAME}.d)
                if [ -f "$l_kfile" ]; then
                    l_gpname="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_kfile")"
                    echo " - updating dconf profile name to \"$l_gpname\""
                fi
                
                [ ! -f "$l_kfile" ] && l_kfile="/etc/dconf/db/$l_gpname.d/00-media-autorun"
                
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
                
                # create dconf directory if it doesn't exist
                l_gpdir="/etc/dconf/db/$l_gpname.d"
                if [ -d "$l_gpdir" ]; then
                    echo " - The dconf database directory \"$l_gpdir\" exists"
                else
                    echo " - creating dconf database directory \"$l_gpdir\""
                    mkdir "$l_gpdir"
                fi
                
                # Clean the kfile before modifying it
                if [ -f "$l_kfile" ]; then
                    echo "Cleaning up duplicate entries in \"$l_kfile\""
                    sed -i '/^\s*autorun-never/d' "$l_kfile"  # Remove all autorun-never entries
                fi
                
                # Check and display current contents of the kfile before modification
                echo "Current contents of \"$l_kfile\":"
                cat "$l_kfile"
                
                # Check if the autorun-never entry is already set
                if grep -Pq -- '^\h*autorun-never\b' "$l_kfile"; then
                    echo " - \"autorun-never\" exists; updating to true"
                    sed -i 's/^\(autorun-never\s*=\s*\).*/\1true/' "$l_kfile"
                else
                    echo " - creating \"autorun-never\" entry in \"$l_kfile\""
                    echo -e "[org/gnome/desktop/media-handling]\nautorun-never=true" >> "$l_kfile"
                fi

                # Display contents after modification
                echo "Contents of \"$l_kfile\" after modification:"
                cat "$l_kfile"
                
                # update dconf database
                dconf update
                
                # Verify if the setting is applied correctly
                if grep -Pqs -- '^\h*autorun-never\h*=\h*true\b' "$l_kfile"; then
                    echo -e "\n- Remediation Result:\n ** SUCCESS **\n - \"autorun-never\" is now set to true in: \"$l_kfile\""
                else
                    echo -e "\n- Remediation Result:\n ** FAILURE **\n - \"autorun-never\" is still not set correctly."
                fi
            fi
        fi
    fi
}
