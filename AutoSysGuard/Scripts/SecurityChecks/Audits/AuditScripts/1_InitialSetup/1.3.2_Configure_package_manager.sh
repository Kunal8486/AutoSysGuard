#!/bin/bash

# Function to check package repositories
check_repositories() {
    echo "Checking package repositories..."
    apt_cache_policy=$(apt-cache policy)
    echo "$apt_cache_policy"

    # Check if there are any repositories defined
    if [[ -z "$apt_cache_policy" ]]; then
        echo "No package repositories configured."
        return 1  # No repositories
    else
        echo "Package repositories are configured."
        return 0  # Repositories exist
    fi
}

# Main script execution
if check_repositories; then
    echo "Repositories configuration is present."
else
    echo "Please configure your package manager repositories according to site policy."
    echo "Refer to the /etc/apt/sources.list file or /etc/apt/sources.list.d/ directory to configure repositories."
    echo "You can edit the sources list using:"
    echo "sudo nano /etc/apt/sources.list"
    echo "or add files to /etc/apt/sources.list.d/"
fi
