#!/bin/bash

# Function to check GPG keys
check_gpg_keys() {
    echo "Checking GPG keys for package manager..."
    gpg_keys=$(apt-key list)

    if [[ -z "$gpg_keys" ]]; then
        echo "No GPG keys configured for the package manager."
        return 1  # No GPG keys found
    else
        echo "GPG keys are configured:"
        echo "$gpg_keys"
        return 0  # GPG keys found
    fi
}

# Main script execution
if check_gpg_keys; then
    echo "GPG keys configuration is valid."
else
    echo "Please update your package manager GPG keys in accordance with site policy."
    echo "You can add new GPG keys using the following command:"
    echo "sudo apt-key add <keyfile>"
    echo "For additional guidance, consult your site policy or the relevant documentation."
fi
