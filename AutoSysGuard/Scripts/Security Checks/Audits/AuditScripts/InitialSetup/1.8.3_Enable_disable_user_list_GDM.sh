#!/usr/bin/env bash

# Audit Script
l_pkgoutput=""
if command -v dpkg-query > /dev/null 2>&1; then
    l_pq="dpkg-query -W"
elif command -v rpm > /dev/null 2>&1; then
    l_pq="rpm -q"
fi

l_pcl="gdm gdm3" # Space-separated list of packages to check
for l_pn in $l_pcl; do
    $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
done

if [ -n "$l_pkgoutput" ]; then
    output="" output2=""

    # Check if "disable-user-list" is enabled
    l_gdmfile="$(grep -Pril '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db)"
    if [ -n "$l_gdmfile" ]; then
        output="$output\n - The \"disable-user-list\" option is enabled in \"$l_gdmfile\""
        l_gdmprofile="$(awk -F\/ '{split($(NF-1),a,".");print a[1]}' <<< "$l_gdmfile")"

        # Check if profile exists in /etc/dconf/profile
        if grep -Pq "^\h*system-db:$l_gdmprofile" /etc/dconf/profile/"$l_gdmprofile"; then
            output="$output\n - The \"$l_gdmprofile\" exists"
        else
            output2="$output2\n - The \"$l_gdmprofile\" doesn't exist"
        fi

        # Check if profile exists in dconf database
        if [ -f "/etc/dconf/db/$l_gdmprofile" ]; then
            output="$output\n - The \"$l_gdmprofile\" profile exists in the dconf database"
        else
            output2="$output2\n - The \"$l_gdmprofile\" profile doesn't exist in the dconf database"
        fi
    else
        output2="$output2\n - The \"disable-user-list\" option is not enabled"
    fi

    # Determine pass or fail
    if [ -z "$output2" ]; then
        echo -e "$l_pkgoutput\n- Audit result:\n *** PASS: ***\n$output\n"
    else
        echo -e "$l_pkgoutput\n- Audit Result:\n *** FAIL: ***\n$output2\n"
        [ -n "$output" ] && echo -e "$output\n"

        # Ask the user if they want to apply remediation
        read -p "Would you like to apply the remediation? (y/n): " user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            # Remediation Script
            l_gdmprofile="gdm" # Set this to the desired profile name according to local policy
            if [ ! -f "/etc/dconf/profile/$l_gdmprofile" ]; then
                echo "Creating profile \"$l_gdmprofile\""
                echo -e "user-db:user\nsystem-db:$l_gdmprofile\nfile-db:/usr/share/$l_gdmprofile/greeter-dconf-defaults" > /etc/dconf/profile/$l_gdmprofile
            fi

            if [ ! -d "/etc/dconf/db/$l_gdmprofile.d/" ]; then
                echo "Creating dconf database directory \"/etc/dconf/db/$l_gdmprofile.d/\""
                mkdir /etc/dconf/db/$l_gdmprofile.d/
            fi

            l_kfile="/etc/dconf/db/$l_gdmprofile.d/00-login-screen"
            if ! grep -Piq '^\h*disable-user-list\h*=\h*true\b' /etc/dconf/db/$l_gdmprofile.d/*; then
                echo "Creating GDM keyfile for machine-wide settings"
                if ! grep -Piq -- '^\h*\[org\/gnome\/login-screen\]' /etc/dconf/db/$l_gdmprofile.d/*; then
                    echo -e "\n[org/gnome/login-screen]\n# Do not show the user list\ndisable-user-list=true" >> "$l_kfile"
                else
                    sed -ri '/^\s*\[org\/gnome\/login-screen\]/ a\# Do not show the user list\ndisable-user-list=true' $(grep -Pil -- '^\h*\[org\/gnome\/login-screen\]' /etc/dconf/db/$l_gdmprofile.d/*)
                fi
            fi

            # Apply changes
            dconf update
            echo -e "\n - Remediation applied successfully."
        else
            echo "Remediation skipped."
        fi
    fi
else
    echo -e "\n\n - GNOME Desktop Manager isn't installed\n - Recommendation is Not Applicable\n- Audit result:\n *** PASS ***\n"
fi
