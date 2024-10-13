# 3.1.5 Ensure SCTP is disabled (Automated)
#!/usr/bin/env bash

{
    l_output="" l_output2="" l_output3="" l_dl="" # Unset output variables
    l_mname="sctp" # set module name
    l_mtype="net" # set module type
    l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
    l_mpath="/lib/modules/**/kernel/$l_mtype"
    l_mpname="$(tr '-' '_' <<< "$l_mname")"
    l_mndir="$(tr '-' '/' <<< "$l_mname")"
    
    module_loadable_chk() {
        # Check if the module is currently loadable
        l_loadable="$(modprobe -n -v "$l_mname")"
        [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "(^\\s*install|\\b$l_mname)\\b" <<< "$l_loadable")"
        if grep -Pq -- '^\\s*install /bin/(true|false)' <<< "$l_loadable"; then
            l_output="$l_output\n - module: \"$l_mname\" is not loadable: \"$l_loadable\""
        else
            l_output2="$l_output2\n - module: \"$l_mname\" is loadable: \"$l_loadable\""
        fi
    }

    module_loaded_chk() {
        # Check if the module is currently loaded
        if ! lsmod | grep "$l_mname" > /dev/null 2>&1; then
            l_output="$l_output\n - module: \"$l_mname\" is not loaded"
        else
            l_output2="$l_output2\n - module: \"$l_mname\" is loaded"
        fi
    }

    module_deny_chk() {
        # Check if the module is deny listed
        l_dl="y"
        if modprobe --showconfig | grep -Pq -- '^\\s*blacklist\\s+'"$l_mpname"'\\b'; then
            l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pls -- '^\\s*blacklist\\s+'$l_mname'\\b' $l_searchloc)\""
        else
            l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed"
        fi
    }

    module_dependency_chk() {
        # Check for dependencies
        if modinfo "$l_mname" | grep -q 'depends:'; then
            l_output2="$l_output2\n - module: \"$l_mname\" has dependencies that may affect its loadability."
            return 1 # Indicate that dependencies exist
        fi
        return 0 # No dependencies
    }

    apply_remediation() {
        echo "Applying remediation steps..."
        # Create necessary files in /etc/modprobe.d/
        echo "install $l_mname /bin/false" | sudo tee /etc/modprobe.d/$l_mname.conf
        echo "blacklist $l_mname" | sudo tee /etc/modprobe.d/${l_mname}-blacklist.conf
        # Unload the module if it is loaded
        if lsmod | grep -q "$l_mname"; then
            sudo modprobe -r "$l_mname"
            echo "Module \"$l_mname\" unloaded."
        fi
        echo "Remediation steps applied."
    }

    # Check if the module exists on the system
    for l_mdir in $l_mpath; do
        if [ -d "$l_mdir/$l_mndir" ] && [ -n "$(ls -A $l_mdir/$l_mndir)" ]; then
            l_output3="$l_output3\n - \"$l_mdir\""
            [ "$l_dl" != "y" ] && module_deny_chk
            if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
                module_loadable_chk
                module_loaded_chk
            fi
        else
            l_output="$l_output\n - module: \"$l_mname\" doesn't exist in \"$l_mdir\""
        fi
    done

    # Call dependency check
    if module_dependency_chk; then
        # If no dependencies, ask user if they want to apply remediation
        echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
        read -p "Do you want to apply the remediation steps? (y/n): " user_input
        if [[ "$user_input" == "y" ]]; then
            apply_remediation
        fi
    else
        echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
    fi
}
