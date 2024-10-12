#!/usr/bin/env bash
{
    l_pkgoutput="" l_output="" l_output2=""

    # Determine system's package manager
    if command -v dpkg-query > /dev/null 2>&1; then
        l_pq="dpkg-query -W"
    elif command -v rpm > /dev/null 2>&1; then
        l_pq="rpm -q"
    fi

    # Check if GDM is installed
    l_pcl="gdm gdm3"  # Space-separated list of packages to check
    for l_pn in $l_pcl; do
        $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="$l_pkgoutput\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
    done

    # Check configuration (if applicable)
    if [ -n "$l_pkgoutput" ]; then
        # Look for autorun-never to determine the profile in use
        l_kfd="/etc/dconf/db/$(grep -Psril '^\h*autorun-never\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

        # If the profile directory exists
        if [ -d "$l_kfd" ]; then
            # Check if autorun-never is locked
            if grep -Prisq '^\h*/org/gnome/desktop/media-handling/autorun-never\b' "$l_kfd"; then
                l_output="$l_output\n - \"autorun-never\" is locked in \"$(grep -Pril '^\h*/org/gnome/desktop/media-handling/autorun-never\b' "$l_kfd")\""
            else
                l_output2="$l_output2\n - \"autorun-never\" is not locked"
            fi
        else
            l_output2="$l_output2\n - \"autorun-never\" is not set so it cannot be locked"
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
            # Remediation starts here
            l_pkgoutput=""  # Reset package output
            for l_pn in $l_pcl; do
                $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="y" && echo -e "\n - Package: \"$l_pn\" exists on the system\n - remediating configuration if needed"
            done

            if [ -n "$l_pkgoutput" ]; then
                # Check configuration again (after potential remediation)
                l_kfd="/etc/dconf/db/$(grep -Psril '^\h*autorun-never\b' /etc/dconf/db/*/ | awk -F'/' '{split($(NF-1),a,".");print a[1]}').d"

                if [ -d "$l_kfd" ]; then
                    # Check if autorun-never is locked
                    if grep -Prisq '^\h*/org/gnome/desktop/media-handling/autorun-never\b' "$l_kfd"; then
                        echo " - \"autorun-never\" is locked in \"$(grep -Pril '^\h*/org/gnome/desktop/media-handling/autorun-never\b' "$l_kfd")\""
                    else
                        echo " - creating entry to lock \"autorun-never\""
                        [ ! -d "$l_kfd"/locks ] && echo "creating directory $l_kfd/locks" && mkdir "$l_kfd"/locks
                        {
                            echo -e '\n# Lock desktop media-handling autorun-never setting'
                            echo '/org/gnome/desktop/media-handling/autorun-never'
                        } >> "$l_kfd"/locks/00-media-autorun
                    fi
                else
                    echo -e " - \"autorun-never\" is not set so it cannot be locked\n - Please follow the recommendation \"Ensure GDM autorun-never is enabled\" and try again"
                fi

                # Update dconf database
                dconf update
            else
                echo -e " - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
            fi
        fi
    fi
}
