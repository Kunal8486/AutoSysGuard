#!/usr/bin/env bash

l_mname="usb-storage" # Set module name
l_mtype="drivers"     # Set module type
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"
config_file="/etc/modprobe.d/$l_mpname.conf" # Define config file path

# Function to ensure the module is not loadable
module_loadable_fix() {
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "(^\h*install|\b$l_mname)\b" <<< "$l_loadable")"
    
    # Check if the module loadable directive is set, if not, set it
    if ! grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
        echo -e "\n - setting module: \"$l_mname\" to be not loadable"
        echo -e "install $l_mname /bin/false" >> "$config_file"
    else
        echo -e "\n - module \"$l_mname\" is already set to not loadable."
    fi
}

# Function to unload the module if it's currently loaded
module_loaded_fix() {
    if lsmod | grep "$l_mname" > /dev/null 2>&1; then
        echo -e "\n - unloading module \"$l_mname\""
        modprobe -r "$l_mname"
    fi
}

# Function to ensure the module is deny-listed (blacklisted)
module_deny_fix() {
    if ! modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$l_mpname\b"; then
        echo -e "\n - deny listing \"$l_mname\""
        echo -e "blacklist $l_mname" >> "$config_file"
    else
        echo -e "\n - module \"$l_mname\" is already deny-listed."
    fi
}

# Apply remediation and validate that the settings are persistent
apply_remediation() {
    for l_mdir in $l_mpath; do
        if [ -d "$l_mdir/$l_mndir" ] && [ -n "$(ls -A $l_mdir/$l_mndir)" ]; then
            echo -e "\n - module: \"$l_mname\" exists in \"$l_mdir\"\n - checking if disabled..."
            
            # Apply the necessary fixes
            module_deny_fix
            if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
                module_loadable_fix
                module_loaded_fix
            fi
        else
            echo -e "\n - module: \"$l_mname\" doesn't exist in \"$l_mdir\"\n"
        fi
    done

    # Recheck after remediation to ensure persistence
    if grep -Pq -- "^\h*install $l_mname /bin/false" "$config_file" && grep -Pq -- "^\h*blacklist $l_mname" "$config_file"; then
        echo -e "\n - Remediation of module: \"$l_mname\" complete and verified as persistent."
    else
        echo -e "\n - Remediation failed or not persisted correctly!"
    fi
}

# Start the remediation
apply_remediation
