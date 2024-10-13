#!/usr/bin/env bash

{
    declare -A HASH_MAP=( ["y"]="yescrypt" ["1"]="md5" ["2"]="blowfish" ["5"]="SHA256" ["6"]="SHA512" ["g"]="gost-yescrypt" )
    CONFIGURED_HASH=$(sed -n "s/^\s*ENCRYPT_METHOD\s*\(.*\)\s*$/\1/p" /etc/login.defs)

    USERS_WITH_ISSUES=()

    for MY_USER in $(sed -n "s/^\(.*\):\\$.*/\1/p" /etc/shadow)
    do
        CURRENT_HASH=$(sed -n "s/${MY_USER}:\\$\(.\).*/\1/p" /etc/shadow)
        if [[ "${HASH_MAP["${CURRENT_HASH}"]^^}" != "${CONFIGURED_HASH^^}" ]]; then
            echo "The password for '${MY_USER}' is using '${HASH_MAP["${CURRENT_HASH}"]}' instead of the configured '${CONFIGURED_HASH}'."
            USERS_WITH_ISSUES+=("${MY_USER}")
        fi
    done

    if [[ ${#USERS_WITH_ISSUES[@]} -eq 0 ]]; then
        echo "All users are using the configured hashing algorithm."
        exit 0
    fi

    read -p "Do you wish to force an immediate change on all users listed above? (y/n): " response

    if [[ "${response,,}" == "y" ]]; then
        UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
        for USER in "${USERS_WITH_ISSUES[@]}"; do
            chage -d 0 "${USER}"
        done
        echo "Password expiration applied to the affected users."
    else
        echo "No changes made."
    fi
}
