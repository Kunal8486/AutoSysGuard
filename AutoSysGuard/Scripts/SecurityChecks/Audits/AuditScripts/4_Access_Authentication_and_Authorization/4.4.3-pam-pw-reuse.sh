#!/usr/bin/env bash

{
    PAM_FILE="/etc/pam.d/common-password"
    PAM_HISTORY_PATTERN='^\s*password\s+required\s+pam_pwhistory\.so\s+remember=[5-9][0-9]*'
    PAM_UNIX_PATTERN='^\s*password\s+\[success=1 default=ignore\]\s+pam_unix\.so.*use_authtok'
    
    # Check for pam_pwhistory.so and pam_unix.so lines
    PAM_HISTORY_OK=$(grep -P "${PAM_HISTORY_PATTERN}" "${PAM_FILE}")
    PAM_UNIX_OK=$(grep -P "${PAM_UNIX_PATTERN}" "${PAM_FILE}")
    
    # Check the order of pam_pwhistory.so and pam_unix.so
    if grep -q 'pam_unix\.so' "${PAM_FILE}" && grep -q 'pam_pwhistory\.so' "${PAM_FILE}"; then
        ORDER_OK=$(awk '/^password/ { if ($0 ~ /pam_unix\.so/) { found_unix=1 } if ($0 ~ /pam_pwhistory\.so/) { if (found_unix) { print 1; exit } } } END { print 0 }' "${PAM_FILE}")
    else
        ORDER_OK=0
    fi

    # Initialize flags for discrepancies
    PAM_HISTORY_ISSUE=false
    PAM_UNIX_ISSUE=false
    ORDER_ISSUE=false

    # Check pam_pwhistory.so configuration
    if [[ -z "${PAM_HISTORY_OK}" ]]; then
        echo "The pam_pwhistory.so line is either missing or does not include 'remember=' with a value of at least 5."
        PAM_HISTORY_ISSUE=true
    else
        echo "pam_pwhistory.so configuration is correct: ${PAM_HISTORY_OK}"
    fi

    # Check pam_unix.so configuration
    if [[ -z "${PAM_UNIX_OK}" ]]; then
        echo "The pam_unix.so line does not include 'use_authtok'."
        PAM_UNIX_ISSUE=true
    else
        echo "pam_unix.so configuration is correct: ${PAM_UNIX_OK}"
    fi

    # Check order of pam_pwhistory.so and pam_unix.so
    if [[ "${ORDER_OK}" -eq 1 ]]; then
        echo "The pam_unix.so line occurs before the pam_pwhistory.so line."
        ORDER_ISSUE=true
    else
        echo "The pam_pwhistory.so line is correctly positioned before the pam_unix.so line."
    fi

    # If all configurations are correct, exit
    if [[ "${PAM_HISTORY_ISSUE}" == false && "${PAM_UNIX_ISSUE}" == false && "${ORDER_ISSUE}" == false ]]; then
        echo "All PAM configurations are correct."
        exit 0
    fi

    # Ask for remediation
    read -p "Do you wish to apply remediation for the above issues? (y/n): " response

    if [[ "${response,,}" == "y" ]]; then
        # Remediate pam_pwhistory.so configuration
        if [[ "${PAM_HISTORY_ISSUE}" == true ]]; then
            echo "Updating ${PAM_FILE} to include pam_pwhistory.so with remember=5..."
            sed -i.bak '/^password\s\+/i password required pam_pwhistory.so remember=5' "${PAM_FILE}"
            echo "Updated PAM history configuration in ${PAM_FILE}."
        fi

        # Remediate pam_unix.so configuration
        if [[ "${PAM_UNIX_ISSUE}" == true ]]; then
            echo "Updating ${PAM_FILE} to include use_authtok in pam_unix.so..."
            sed -i.bak '/^password\s\+\[success=1 default=ignore\]\s\+pam_unix\.so/s/$/ use_authtok/' "${PAM_FILE}"
            echo "Updated PAM unix configuration in ${PAM_FILE}."
        fi

        # Remediate the order of pam_pwhistory.so and pam_unix.so
        if [[ "${ORDER_ISSUE}" == false ]]; then
            echo "Ensuring pam_pwhistory.so is placed before pam_unix.so..."
            sed -i.bak '/^password\s\+required\s+pam_unix\.so/ i password required pam_pwhistory.so remember=5' "${PAM_FILE}"
            echo "Adjusted the order of PAM configuration in ${PAM_FILE}."
        fi

        echo "Remediation applied successfully."
    else
        echo "No changes made."
    fi
}
