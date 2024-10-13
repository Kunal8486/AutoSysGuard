#!/bin/bash

# Function to check PATH integrity
check_path_integrity() {
    local path="$1"
    local issues_found=0
    echo "Checking root user's PATH integrity..."

    # Check for empty directories and trailing colons
    if echo "$path" | grep -q "::"; then
        echo "Warning: root's PATH contains an empty directory (::)"
        issues_found=1
    fi
    if echo "$path" | grep -q ":$"; then
        echo "Warning: root's PATH contains a trailing colon (:)"
        issues_found=1
    fi

    # Check each directory in the PATH
    IFS=':' read -r -a dirs <<< "$path"
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            ls -ldH "$dir" | awk -v dir="$dir" -v issues_found="$issues_found" '
            $9 == "." {print "Warning: PATH contains current working directory (.)"; issues_found=1}
            $3 != "root" {print "Warning:", dir, "is not owned by root"; issues_found=1}
            substr($1,6,1) != "-" {print "Warning:", dir, "is group writable"; issues_found=1}
            substr($1,9,1) != "-" {print "Warning:", dir, "is world writable"; issues_found=1}
            '
        else
            echo "Warning: $dir is not a directory"
            issues_found=1
        fi
    done

    return $issues_found
}

# Function to remediate issues
remediate_path() {
    local path="$1"
    echo "Do you want to correct any issues found in root's PATH? (y/n): "
    read -r choice

    if [[ "$choice" == "y" ]]; then
        IFS=':' read -r -a dirs <<< "$path"
        for dir in "${dirs[@]}"; do
            # Handle empty directories and trailing colons
            if [ -d "$dir" ]; then
                # Change ownership to root if not already owned by root
                if [ "$(ls -ldH "$dir" | awk '{print $3}')" != "root" ]; then
                    echo "Changing ownership of $dir to root..."
                    chown root:root "$dir"
                fi
                
                # Remove group write permission
                if [ "$(ls -ldH "$dir" | awk '{print substr($1,6,1)}')" != "-" ]; then
                    echo "Removing group write permission from $dir..."
                    chmod g-w "$dir"
                fi
                
                # Remove world write permission
                if [ "$(ls -ldH "$dir" | awk '{print substr($1,9,1)}')" != "-" ]; then
                    echo "Removing world write permission from $dir..."
                    chmod o-w "$dir"
                fi
            fi
        done
        echo "Remediation completed."
    else
        echo "No changes were made to root's PATH."
    fi
}

# Get the root user's PATH
root_path="$(sudo -Hiu root env | grep '^PATH' | cut -d= -f2)"
check_path_integrity "$root_path"

# Check if any issues were found
if [ $? -ne 0 ]; then
    remediate_path "$root_path"
else
    echo "No issues found in root's PATH."
fi
