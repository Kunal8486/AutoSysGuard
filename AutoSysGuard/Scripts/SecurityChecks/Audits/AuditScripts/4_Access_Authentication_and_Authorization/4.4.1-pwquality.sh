#!/usr/bin/env bash

{
    PWQUALITY_CONF="/etc/security/pwquality.conf"
    COMMON_PASSWORD_FILE="/etc/pam.d/common-password"
    
    # Check for minimum password length
    MINLEN_PATTERN='^\s*minlen\s*=\s*14'
    MINLEN_OK=$(grep -E "${MINLEN_PATTERN}" "${PWQUALITY_CONF}")

    # Check for minimum password complexity
    MINCLASS_PATTERN='^\s*minclass\s*=\s*4'
    MINCLASS_OK=$(grep -E "${MINCLASS_PATTERN}" "${PWQUALITY_CONF}")

    # Option 2 checks for dcredit, ucredit, lcredit, ocredit
    D_CREDIT_PATTERN='^\s*dcredit\s*=\s*-1'
    U_CREDIT_PATTERN='^\s*ucredit\s*=\s*-1'
    L_CREDIT_PATTERN='^\s*lcredit\s*=\s*-1'
    O_CREDIT_PATTERN='^\s*ocredit\s*=\s*-1'

    D_CREDIT_OK=$(grep -E "${D_CREDIT_PATTERN}" "${PWQUALITY_CONF}")
    U_CREDIT_OK=$(grep -E "${U_CREDIT_PATTERN}" "${PWQUALITY_CONF}")
    L_CREDIT_OK=$(grep -E "${L_CREDIT_PATTERN}" "${PWQUALITY_CONF}")
    O_CREDIT_OK=$(grep -E "${O_CREDIT_PATTERN}" "${PWQUALITY_CONF}")

    # Check if pam_pwquality.so is enabled
    PAM_PWQUALITY_PATTERN='^\s*password\s+[^#\n\r]+\s+pam_pwquality\.so\b'
    PAM_PWQUALITY_OK=$(grep -P "${PAM_PWQUALITY_PATTERN}" "${COMMON_PASSWORD_FILE}")

    # Initialize flags for discrepancies
    PW_LENGTH_ISSUE=false
    PW_COMPLEXITY_ISSUE=false
    PAM_PWQUALITY_ISSUE=false

    # Check password length
    if [[ -z "${MINLEN_OK}" ]]; then
        echo "The minimum password length is not set to 14 in ${PWQUALITY_CONF}."
        PW_LENGTH_ISSUE=true
    else
        echo "Minimum password length is correct: ${MINLEN_OK}"
    fi

    # Check password complexity (Option 1)
    if [[ -z "${MINCLASS_OK}" ]]; then
        echo "The minimum password complexity (minclass) is not set to 4 in ${PWQUALITY_CONF}."
        PW_COMPLEXITY_ISSUE=true
    else
        echo "Minimum password complexity (minclass) is correct: ${MINCLASS_OK}"
    fi

    # Check password complexity (Option 2)
    if [[ -z "${D_CREDIT_OK}" || -z "${U_CREDIT_OK}" || -z "${L_CREDIT_OK}" || -z "${O_CREDIT_OK}" ]]; then
        echo "Password complexity credits are not correctly set in ${PWQUALITY_CONF}."
        PW_COMPLEXITY_ISSUE=true
    else
        echo "Password complexity credits are correct: dcredit=${D_CREDIT_OK}, ucredit=${U_CREDIT_OK}, lcredit=${L_CREDIT_OK}, ocredit=${O_CREDIT_OK}"
    fi

    # Check if pam_pwquality.so is enabled
    if [[ -z "${PAM_PWQUALITY_OK}" ]]; then
        echo "The pam_pwquality.so module is not enabled in ${COMMON_PASSWORD_FILE}."
        PAM_PWQUALITY_ISSUE=true
    else
        echo "pam_pwquality.so is correctly configured: ${PAM_PWQUALITY_OK}"
    fi

    # If all configurations are correct, exit
    if [[ "${PW_LENGTH_ISSUE}" == false && "${PW_COMPLEXITY_ISSUE}" == false && "${PAM_PWQUALITY_ISSUE}" == false ]]; then
        echo "All password creation requirements are correct."
        exit 0
    fi

    # Ask for remediation
    read -p "Do you wish to apply remediation for the above issues? (y/n): " response

    if [[ "${response,,}" == "y" ]]; then
        # Remediate minimum password length
        if [[ "${PW_LENGTH_ISSUE}" == true ]]; then
            echo "Updating ${PWQUALITY_CONF} to set minlen=14..."
            sed -i.bak 's/^\s*minlen\s*=.*/minlen = 14/' "${PWQUALITY_CONF}" || echo "Failed to set minlen in ${PWQUALITY_CONF}."
            echo "Updated minimum password length in ${PWQUALITY_CONF}."
        fi

        # Remediate minimum password complexity
        if [[ "${PW_COMPLEXITY_ISSUE}" == true ]]; then
            echo "Updating ${PWQUALITY_CONF} for password complexity..."
            sed -i.bak 's/^\s*minclass\s*=.*/minclass = 4/' "${PWQUALITY_CONF}" || echo "Failed to set minclass in ${PWQUALITY_CONF}."
            echo "Updated minimum password complexity in ${PWQUALITY_CONF}."
            echo "Setting dcredit, ucredit, lcredit, and ocredit..."
            echo "dcredit = -1" >> "${PWQUALITY_CONF}"
            echo "ucredit = -1" >> "${PWQUALITY_CONF}"
            echo "lcredit = -1" >> "${PWQUALITY_CONF}"
            echo "ocredit = -1" >> "${PWQUALITY_CONF}"
            echo "Updated password complexity credits in ${PWQUALITY_CONF}."
        fi

        # Remediate pam_pwquality.so configuration
        if [[ "${PAM_PWQUALITY_ISSUE}" == true ]]; then
            echo "Updating ${COMMON_PASSWORD_FILE} to include pam_pwquality.so..."
            sed -i.bak '/^password\s\+/i password requisite pam_pwquality.so retry=3' "${COMMON_PASSWORD_FILE}"
            echo "Updated pam_pwquality configuration in ${COMMON_PASSWORD_FILE}."
        fi

        echo "Remediation applied successfully."
    else
        echo "No changes made."
    fi
}
