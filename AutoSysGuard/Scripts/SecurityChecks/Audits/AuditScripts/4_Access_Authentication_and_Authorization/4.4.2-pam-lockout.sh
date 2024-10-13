#!/usr/bin/env bash

{
    COMMON_AUTH_FILE="/etc/pam.d/common-auth"
    COMMON_ACCOUNT_FILE="/etc/pam.d/common-account"
    
    # Check pam_tally2.so configuration in common-auth
    TALLY_PATTERN='auth\s+required\s+pam_tally2\.so\s+onerr=fail\s+audit\s+silent\s+deny=[0-5]'
    TALLY_OK=$(grep -E "${TALLY_PATTERN}" "${COMMON_AUTH_FILE}")

    # Check pam_deny.so and pam_tally2.so configurations in common-account
    DENY_TALLY_PATTERN='account\s+requisite\s+pam_deny\.so'
    TALLY_ACCOUNT_PATTERN='account\s+required\s+pam_tally2\.so'

    DENY_OK=$(grep -E "${DENY_TALLY_PATTERN}" "${COMMON_ACCOUNT_FILE}")
    TALLY_ACCOUNT_OK=$(grep -E "${TALLY_ACCOUNT_PATTERN}" "${COMMON_ACCOUNT_FILE}")

    # Initialize flags for discrepancies
    TALLY_ISSUE=false
    DENY_ISSUE=false
    TALLY_ACCOUNT_ISSUE=false

    # Check pam_tally2.so configuration
    if [[ -z "${TALLY_OK}" ]]; then
        echo "The pam_tally2.so line is either missing or 'deny=' is not set to 5 or less in ${COMMON_AUTH_FILE}."
        TALLY_ISSUE=true
    else
        echo "pam_tally2.so configuration is correct: ${TALLY_OK}"
    fi

    # Check pam_deny.so configuration
    if [[ -z "${DENY_OK}" ]]; then
        echo "The pam_deny.so line is missing in ${COMMON_ACCOUNT_FILE}."
        DENY_ISSUE=true
    else
        echo "pam_deny.so configuration is correct: ${DENY_OK}"
    fi

    # Check pam_tally2.so in common-account
    if [[ -z "${TALLY_ACCOUNT_OK}" ]]; then
        echo "The pam_tally2.so line is missing in ${COMMON_ACCOUNT_FILE}."
        TALLY_ACCOUNT_ISSUE=true
    else
        echo "pam_tally2.so configuration is correct: ${TALLY_ACCOUNT_OK}"
    fi

    # If all configurations are correct, exit
    if [[ "${TALLY_ISSUE}" == false && "${DENY_ISSUE}" == false && "${TALLY_ACCOUNT_ISSUE}" == false ]]; then
        echo "All PAM configurations are correct."
        exit 0
    fi

    # Ask for remediation
    read -p "Do you wish to apply remediation for the above issues? (y/n): " response

    if [[ "${response,,}" == "y" ]]; then
        # Remediate pam_tally2.so configuration
        if [[ "${TALLY_ISSUE}" == true ]]; then
            echo "Updating ${COMMON_AUTH_FILE} to include pam_tally2.so..."
            echo "auth required pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900" >> "${COMMON_AUTH_FILE}"
            echo "Updated PAM tally configuration in ${COMMON_AUTH_FILE}."
        fi

        # Remediate pam_deny.so configuration
        if [[ "${DENY_ISSUE}" == true ]]; then
            echo "Updating ${COMMON_ACCOUNT_FILE} to include pam_deny.so..."
            sed -i.bak '/^account\s\+/i account requisite pam_deny.so' "${COMMON_ACCOUNT_FILE}"
            echo "Updated PAM deny configuration in ${COMMON_ACCOUNT_FILE}."
        fi

        # Remediate pam_tally2.so in common-account
        if [[ "${TALLY_ACCOUNT_ISSUE}" == true ]]; then
            echo "Updating ${COMMON_ACCOUNT_FILE} to include pam_tally2.so..."
            sed -i.bak '/^account\s\+/a account required pam_tally2.so' "${COMMON_ACCOUNT_FILE}"
            echo "Updated PAM tally configuration in ${COMMON_ACCOUNT_FILE}."
        fi

        echo "Remediation applied successfully."
    else
        echo "No changes made."
    fi
}
