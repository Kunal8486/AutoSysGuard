# 3.1.4 Ensure DCCP is disabled (Automated)
#!/usr/bin/env bash

# Initialize output variables
l_output="" 
l_output2="" 
l_output3="" 
l_dl="" 

# Set module name and type
l_mname="dccp" 
l_mtype="net" 
l_searchloc="/etc/modprobe.d/*.conf"
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"

module_loadable_chk() {
    # Check if the module is currently loadable
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "^\h*install|\b$l_mname)\b" <<< "$l_loadable")"
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
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
    if modprobe --showconfig | grep -Pq -- '^\h*blacklist\h+'"$l_mpname"'\b'; then
        l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pls -- "^\h*blacklist\h+$l_mname\b" $l_searchloc)\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed"
    fi
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

# Report results
if [ -n "$l_output3" ]; then
    echo -e "\n\n -- INFO --\n - module: \"$l_mname\" exists in:$l_output3"
fi
if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"

    # Prompt user for remediation
    read -p "Do you want to apply the remediation steps? (y/n): " choice
    if [[ "$choice" == [Yy] ]]; then
        echo "Applying remediation steps..."

        # Create files for remediation
        echo "install $l_mname /bin/false" > /etc/modprobe.d/$l_mname.conf
        echo "blacklist $l_mname" > /etc/modprobe.d/$l_mname-blacklist.conf

        # Unload dccp from the kernel if loaded
        if lsmod | grep "$l_mname" > /dev/null 2>&1; then
            modprobe -r "$l_mname"
            echo "Module $l_mname unloaded from the kernel."
        fi
        
        echo "Remediation steps applied."
    else
        echo "Remediation steps were not applied."
    fi
fi
