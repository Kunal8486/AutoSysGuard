#!/usr/bin/env bash

{
    # Determine system's package manager
    l_pkgoutput=""
    if command -v dpkg-query > /dev/null 2>&1; then
        l_pq="dpkg-query -W"
    elif command -v rpm > /dev/null 2>&1; then
        l_pq="rpm -q"
    fi

    # Check if GNOME Desktop Manager (GDM or GDM3) is installed
    l_pcl="gdm gdm3"  # Space-separated list of packages to check
    for l_pn in $l_pcl; do
        $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
    done

    # Check configuration (if applicable)
    if [ -n "$l_pkgoutput" ]; then
        l_output="" l_output2=""

        # Determine profiles in use by checking idle-delay and lock-delay
        l_kfd="/etc/dconf/db/$(grep -Psril '^\h*idle-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"
        l_kfd2="/etc/dconf/db/$(grep -Psril '^\h*lock-delay\h*=\h*uint32\h+\d+\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

        # Check and lock "idle-delay"
        if [ -d "$l_kfd" ]; then
            if grep -Prilq '\/org\/gnome\/desktop\/session\/idle-delay\b' "$l_kfd"; then
                l_output="$l_output\n - \"idle-delay\" is locked in \"$(grep -Pril '\/org\/gnome\/desktop\/session\/idle-delay\b' "$l_kfd")\""
            else
                l_output2="$l_output2\n - \"idle-delay\" is not locked"
            fi
        else
            l_output2="$l_output2\n - \"idle-delay\" is not set so it can not be locked"
        fi

        # Check and lock "lock-delay"
        if [ -d "$l_kfd2" ]; then
            if grep -Prilq '\/org\/gnome\/desktop\/screensaver\/lock-delay\b' "$l_kfd2"; then
                l_output="$l_output\n - \"lock-delay\" is locked in \"$(grep -Pril '\/org\/gnome\/desktop\/screensaver\/lock-delay\b' "$l_kfd2")\""
            else
                l_output2="$l_output2\n - \"lock-delay\" is not locked"
            fi
        else
            l_output2="$l_output2\n - \"lock-delay\" is not set so it can not be locked"
        fi

        # Report the audit result
        [ -n "$l_pkgoutput" ] && echo -e "\n$l_pkgoutput"
        if [ -z "$l_output2" ]; then
            echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
        else
            echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
            [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"

            # Prompt for remediation if audit fails
            echo -n "Would you like to apply the remediation? (y/n): "
            read l_response
            if [[ "$l_response" == "y" ]]; then
                echo "Applying remediation..."

                # Remediation for "idle-delay"
                if [ ! -d "$l_kfd/locks" ]; then
                    echo "Creating directory $l_kfd/locks"
                    mkdir -p "$l_kfd/locks"
                fi
                if ! grep -q '/org/gnome/desktop/session/idle-delay' "$l_kfd/locks/00-screensaver"; then
                    echo "Locking \"idle-delay\""
                    {
                        echo -e '\n# Lock desktop screensaver idle-delay setting'
                        echo '/org/gnome/desktop/session/idle-delay'
                    } >> "$l_kfd/locks/00-screensaver"
                fi

                # Remediation for "lock-delay"
                if [ ! -d "$l_kfd2/locks" ]; then
                    echo "Creating directory $l_kfd2/locks"
                    mkdir -p "$l_kfd2/locks"
                fi
                if ! grep -q '/org/gnome/desktop/screensaver/lock-delay' "$l_kfd2/locks/00-screensaver"; then
                    echo "Locking \"lock-delay\""
                    {
                        echo -e '\n# Lock desktop screensaver lock-delay setting'
                        echo '/org/gnome/desktop/screensaver/lock-delay'
                    } >> "$l_kfd2/locks/00-screensaver"
                fi

                # Update the dconf system database
                echo "Updating dconf system database..."
                sudo dconf update

                echo "Remediation applied successfully. Please log out and back in for changes to take effect."
            else
                echo "Remediation skipped."
            fi
        fi
    else
        echo -e " - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
    fi
}
