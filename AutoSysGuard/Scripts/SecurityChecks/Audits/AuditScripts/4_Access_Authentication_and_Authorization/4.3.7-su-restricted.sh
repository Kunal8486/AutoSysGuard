#!/usr/bin/env bash

{
    PAM_SU_FILE="/etc/pam.d/su"
    GROUP_NAME="sugroup"  # Change this to your desired group name

    # Check if pam_wheel.so is configured correctly in /etc/pam.d/su
    PAM_WHEEL_PATTERN='^\s*auth\s+(?:required|requisite)\s+pam_wheel\.so\s+(?:[^#\n\r]+\s+)?(use_uid\b|group=\H+\b)\s+(?:[^#\n\r]+\s+)?(use_uid\b|group=\H+\b)'
    PAM_WHEEL_OK=$(grep -P "${PAM_WHEEL_PATTERN}" "${PAM_SU_FILE}")

    # Check if the specified group is empty
    GROUP_CHECK=$(grep "${GROUP_NAME}" /etc/group)

    # Initialize flags for discrepancies
    PAM_WHEEL_ISSUE=false
    GROUP_ISSUE=false

    # Verify pam_wheel.so configuration
    if [[ -z "${PAM_WHEEL_OK}" ]]; then
        echo "The pam_wheel.so configuration is incorrect in ${PAM_SU_FILE}."
        PAM_WHEEL_ISSUE=true
    else
        echo "pam_wheel.so configuration is correct: ${PAM_WHEEL_OK}"
    fi

    # Check if the group is empty
    if [[ -n "${GROUP_CHECK}" && "${GROUP_CHECK}" != *":"* ]]; then
        echo "The group '${GROUP_NAME}' contains users."
        GROUP_ISSUE=true
    else
        echo "The group '${GROUP_NAME}' is empty or does not exist."
    fi

    # If all configurations are correct, exit
    if [[ "${PAM_WHEEL_ISSUE}" == false && "${GROUP_ISSUE}" == false ]]; then
        echo "All pam_wheel.so requirements are correct."
        exit 0
    fi

    # Ask for remediation
    read -p "Do you wish to apply remediation for the above issues? (y/n): " response

    if [[ "${response,,}" == "y" ]]; then
        # Remediate pam_wheel.so configuration
        if [[ "${PAM_WHEEL_ISSUE}" == true ]]; then
            echo "Updating ${PAM_SU_FILE} to include pam_wheel.so configuration..."
            echo "auth required pam_wheel.so use_uid group=${GROUP_NAME}" >> "${PAM_SU_FILE}"
            echo "Added pam_wheel.so configuration to ${PAM_SU_FILE}."
        fi

        # Remediate the empty group
        if [[ "${GROUP_ISSUE}" == true ]]; then
            if ! grep -q "${GROUP_NAME}" /etc/group; then
                echo "Creating the group '${GROUP_NAME}'..."
                groupadd "${GROUP_NAME}"
                echo "Created group '${GROUP_NAME}'."
            fi
            echo "Please ensure the group '${GROUP_NAME}' remains empty."
        fi

        echo "Remediation applied successfully."
    else
        echo "No changes made."
    fi
}
