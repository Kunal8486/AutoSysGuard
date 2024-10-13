#!/usr/bin/env bash

{
    # Check pam_unix.so configuration for sha512
    PAM_FILE="/etc/pam.d/common-password"
    ENCRYPT_METHOD_FILE="/etc/login.defs"
    SHA512_PATTERN='^\h*password\h+[^#\n\r]+\h+pam_unix.so([^#\n\r]+\h+)?(sha512|yescrypt)\b'
    ENCRYPT_METHOD_PATTERN='^\h*ENCRYPT_METHOD\h+"?(sha512|yescrypt)\b'

    PAM_OK=$(grep -Pi -- "${SHA512_PATTERN}" "${PAM_FILE}")
    ENCRYPT_OK=$(grep -Pi -- "${ENCRYPT_METHOD_PATTERN}" "${ENCRYPT_METHOD_FILE}")

    # Initialize flags for discrepancies
    PAM_ISSUE=false
    ENCRYPT_METHOD_ISSUE=false

    # Check PAM configuration
    if [[ -z "${PAM_OK}" ]]; then
        echo "The pam_unix.so configuration does not include 'sha512' in ${PAM_FILE}."
        PAM_ISSUE=true
    else
        echo "PAM configuration is correct: ${PAM_OK}"
    fi

    # Check ENCRYPT_METHOD in login.defs
    if [[ -z "${ENCRYPT_OK}" ]]; then
        echo "The ENCRYPT_METHOD is not set to 'SHA512' in ${ENCRYPT_METHOD_FILE}."
        ENCRYPT_METHOD_ISSUE=true
    else
        echo "ENCRYPT_METHOD configuration is correct: ${ENCRYPT_OK}"
    fi

    # If both configurations are correct, exit
    if [[ "${PAM_ISSUE}" == false && "${ENCRYPT_METHOD_ISSUE}" == false ]]; then
        echo "Both PAM and ENCRYPT_METHOD configurations are correct."
        exit 0
    fi

    # Ask for remediation
    read -p "Do you wish to apply remediation for the above issues? (y/n): " response

    if [[ "${response,,}" == "y" ]]; then
        # Remediate PAM configuration
        if [[ "${PAM_ISSUE}" == true ]]; then
            echo "Updating ${PAM_FILE} to include sha512..."
            sed -i.bak '/^password/s/pam_unix.so.*/& sha512/' "${PAM_FILE}"
            echo "Updated PAM configuration in ${PAM_FILE}."
        fi

        # Remediate ENCRYPT_METHOD configuration
        if [[ "${ENCRYPT_METHOD_ISSUE}" == true ]]; then
            echo "Updating ${ENCRYPT_METHOD_FILE} to set ENCRYPT_METHOD to SHA512..."
            sed -i.bak '/^ENCRYPT_METHOD/s/=.*/= SHA512/' "${ENCRYPT_METHOD_FILE}"
            echo "Updated ENCRYPT_METHOD in ${ENCRYPT_METHOD_FILE}."
        fi

        echo "Remediation applied successfully."
    else
        echo "No changes made."
    fi
}
