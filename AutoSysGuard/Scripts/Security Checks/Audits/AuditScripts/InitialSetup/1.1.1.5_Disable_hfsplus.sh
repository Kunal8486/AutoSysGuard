#!/usr/bin/env bash
{
l_output="" l_output2="" l_output3="" l_dl="" # Unset output variables
l_mname="hfsplus" # set module name
l_mtype="fs" # set module type
l_searchloc="/lib/modprobe.d/*.conf /usr/local/lib/modprobe.d/*.conf /run/modprobe.d/*.conf /etc/modprobe.d/*.conf"
l_mpath="/lib/modules/**/kernel/$l_mtype"
l_mpname="$(tr '-' '_' <<< "$l_mname")"
l_mndir="$(tr '-' '/' <<< "$l_mname")"

module_loadable_chk() {
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "(^\h*install|\b$l_mname)\b" <<< "$l_loadable")"
    if grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
        l_output="$l_output\n - module: \"$l_mname\" is not loadable: \"$l_loadable\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is loadable: \"$l_loadable\""
    fi
}

module_loaded_chk() {
    if ! lsmod | grep "$l_mname" > /dev/null 2>&1; then
        l_output="$l_output\n - module: \"$l_mname\" is not loaded"
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is loaded"
    fi
}

module_deny_chk() {
    l_dl="y"
    if modprobe --showconfig | grep -Pq -- '^\h*blacklist\h+'"$l_mpname"'\b'; then
        l_output="$l_output\n - module: \"$l_mname\" is deny listed in: \"$(grep -Pls -- "^\h*blacklist\h+$l_mname\b" $l_searchloc)\""
    else
        l_output2="$l_output2\n - module: \"$l_mname\" is not deny listed"
    fi
}

module_loadable_fix() {
    l_loadable="$(modprobe -n -v "$l_mname")"
    [ "$(wc -l <<< "$l_loadable")" -gt "1" ] && l_loadable="$(grep -P -- "(^\h*install|\b$l_mname)\b" <<< "$l_loadable")"
    if ! grep -Pq -- '^\h*install \/bin\/(true|false)' <<< "$l_loadable"; then
        read -p "Set module: \"$l_mname\" to be not loadable? (y/n) " confirm
        if [[ $confirm == [yY] ]]; then
            echo -e "\n - setting module: \"$l_mname\" to be not loadable"
            echo -e "install $l_mname /bin/false" >> /etc/modprobe.d/"$l_mpname".conf
        fi
    fi
}

module_loaded_fix() {
    if lsmod | grep "$l_mname" > /dev/null 2>&1; then
        read -p "Unload module \"$l_mname\"? (y/n) " confirm
        if [[ $confirm == [yY] ]]; then
            echo -e "\n - unloading module \"$l_mname\""
            modprobe -r "$l_mname"
        fi
    fi
}

module_deny_fix() {
    if ! modprobe --showconfig | grep -Pq -- "^\h*blacklist\h+$l_mpname\b"; then
        read -p "Deny list \"$l_mname\"? (y/n) " confirm
        if [[ $confirm == [yY] ]]; then
            echo -e "\n - deny listing \"$l_mname\""
            echo -e "blacklist $l_mname" >> /etc/modprobe.d/"$l_mpname".conf
        fi
    fi
}

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

[ -n "$l_output3" ] && echo -e "\n\n -- INFO --\n - module: \"$l_mname\" exists in:$l_output3"
if [ -z "$l_output2" ]; then
    echo -e "\n- Audit Result:\n ** PASS **\n$l_output\n"
else
    echo -e "\n- Audit Result:\n ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
    [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
fi

# Remediation
for l_mdir in $l_mpath; do
    if [ -d "$l_mdir/$l_mndir" ] && [ -n "$(ls -A $l_mdir/$l_mndir)" ]; then
        echo -e "\n - module: \"$l_mname\" exists in \"$l_mdir\"\n - checking if disabled..."
        module_deny_fix
        if [ "$l_mdir" = "/lib/modules/$(uname -r)/kernel/$l_mtype" ]; then
            module_loadable_fix
            module_loaded_fix
        fi
    else
        echo -e "\n - module: \"$l_mname\" doesn't exist in \"$l_mdir\"\n"
    fi
done
echo -e "\n - remediation of module: \"$l_mname\" complete\n"
}
