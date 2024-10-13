#!/usr/bin/env bash
{
    passing=""
    remediation_needed=false

    # Audit: Verify default user umask is correctly set
    if grep -Eiq '^\s*UMASK\s+(0[0-7][2-7]7|[0-7][2-7]7)\b' /etc/login.defs && \
       grep -Eqi '^\s*USERGROUPS_ENAB\s*"?no"?\b' /etc/login.defs && \
       grep -Eq '^\s*session\s+(optional|requisite|required)\s+pam_umask\.so\b' /etc/pam.d/common-session && \
       grep -REiq '^\s*UMASK\s+\s*(0[0-7][2-7]7|[0-7][2-7]7|u=(r?|w?|x?)(r?|w?|x?)(r?|w?|x?),g=(r?x?|x?r?),o=)\b' /etc/profile* /etc/bash.bashrc*; then
        passing=true
        echo "Default user umask is set correctly."
    else
        passing=false
        echo "Audit failed: Default user umask is not set correctly."
    fi

    # Audit: Verify no less restrictive system-wide umask is set
    if grep -RPi '(^|^[^#]*)\s*umask\s+([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b|[0-7][01][0-7]\b|[0-7][0-7][0-6]\b|(u=[rwx]{0,3},)?(g=[rwx]{0,3},)?o=[rwx]+\b|(u=[rwx]{1,3},)?g=[^rx]{1,3}(,o=[rwx]{0,3})?\b)' /etc/login.defs /etc/profile* /etc/bash.bashrc*; then
        echo "Audit failed: Less restrictive system-wide umask detected."
        passing=false
    fi

    # Check if audit passes
    if [ "$passing" = true ]; then
        echo "Audit passed: Default user umask is correctly configured."
    else
        echo "Audit failed: Issues found with umask configuration."
        remediation_needed=true
    fi

    # Prompt user for remediation if audit fails
    if [ "$remediation_needed" = true ]; then
        read -p "Would you like to apply remediation? (y/n): " apply_remed
        if [[ "$apply_remed" == "y" ]]; then
            echo "Applying remediation..."

            # Remediation: Modify /etc/login.defs and other related files
            sed -i '/^\s*UMASK/d' /etc/login.defs
            sed -i '/^\s*USERGROUPS_ENAB/d' /etc/login.defs
            echo "UMASK 027" >> /etc/login.defs
            echo "USERGROUPS_ENAB no" >> /etc/login.defs

            # Modify /etc/pam.d/common-session for pam_umask.so
            grep -q 'pam_umask.so' /etc/pam.d/common-session || echo "session optional pam_umask.so" >> /etc/pam.d/common-session

            # Set umask in /etc/profile.d/set_umask.sh
            echo "umask 027" > /etc/profile.d/set_umask.sh

            echo "Remediation applied: Default umask set to 027."
        else
            echo "No remediation applied."
        fi
    fi
}
