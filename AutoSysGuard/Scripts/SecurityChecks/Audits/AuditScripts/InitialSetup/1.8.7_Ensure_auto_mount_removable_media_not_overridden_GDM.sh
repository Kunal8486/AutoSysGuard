#!/usr/bin/env bash
{
    # Check if GNOME Desktop Manager is installed. If package isn't installed, recommendation is Not Applicable
    l_pkgoutput=""
    if command -v dpkg-query > /dev/null 2>&1; then
        l_pq="dpkg-query -W"
    elif command -v rpm > /dev/null 2>&1; then
        l_pq="rpm -q"
    fi

    # Check if GDM is installed
    l_pcl="gdm gdm3" # Space-separated list of packages to check
    for l_pn in $l_pcl; do
        $l_pq "$l_pn" > /dev/null 2>&1 && l_pkgoutput="y" && echo -e "\n - Package: \"$l_pn\" exists on the system\n - checking configuration"
    done

    # Check configuration (If applicable)
    if [ -n "$l_pkgoutput" ]; then
        l_output="" l_output2=""

        # Check for dconf files and settings
        l_kfd="/etc/dconf/db/local.d/"
        if [ -d "$l_kfd" ]; then
            # Check if "automount" is locked
            if grep -r -q '^\s*automount\s*=\s*true' "$l_kfd" 2>/dev/null; then
                l_output="$l_output\n - \"automount\" is locked"
            else
                l_output2="$l_output2\n - \"automount\" is not set or not locked"
            fi

            # Check if "automount-open" is locked
            if grep -r -q '^\s*automount-open\s*=\s*true' "$l_kfd" 2>/dev/null; then
                l_output="$l_output\n - \"automount-open\" is locked"
            else
                l_output2="$l_output2\n - \"automount-open\" is not locked"
            fi
        else
            echo -e " - Directory $l_kfd does not exist."
            exit
        fi
    else
        echo -e " - GNOME Desktop Manager package is not installed on the system\n - Recommendation is not applicable"
        exit
    fi

    # Report results. If no failures output in l_output2, we pass
    [ -n "$l_pkgoutput" ] && echo -e "\n$l_pkgoutput"
    if [ -z "$l_output2" ]; then
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    else
        echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
        [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
        
        # Prompt user for remediation
        read -p "Do you want to apply remediation? (y/n): " apply_remediation
        if [[ "$apply_remediation" == "y" ]]; then
            echo "Applying remediation..."

            # Remediation logic
            if [ -d "$l_kfd" ]; then
                # Lock "automount"
                if ! grep -r -q '^\s*automount\s*=\s*true' "$l_kfd"; then
                    echo " - creating entry to lock \"automount\""
                    echo -e "\n[org/gnome/desktop/media-handling]\nautomount=true" | sudo tee "$l_kfd/00-media-automount.lock" > /dev/null
                else
                    echo " - \"automount\" is already locked"
                fi

                # Lock "automount-open"
                if ! grep -r -q '^\s*automount-open\s*=\s*true' "$l_kfd"; then
                    echo " - creating entry to lock \"automount-open\""
                    echo -e "\n[org/gnome/desktop/media-handling]\nautomount-open=true" | sudo tee "$l_kfd/00-media-automount-open.lock" > /dev/null
                else
                    echo " - \"automount-open\" is already locked"
                fi
            else
                echo -e " - \"automount\" is not set so it cannot be locked\n - Please follow Recommendation \"Ensure GDM automatic mounting of removable media is disabled\" and follow this Recommendation again"
            fi
            
            # Update dconf database
            dconf update
            echo "Remediation applied successfully."
        else
            echo "Remediation not applied."
        fi
    fi
}
