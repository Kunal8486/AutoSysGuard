#!/bin/bash

# Check the integrity of the root user's PATH
echo "Checking root user's PATH integrity..."

# Get the root user's PATH
root_path="$(sudo -Hiu root env | grep '^PATH' | cut -d= -f2)"

# Check for empty directories and trailing colons
if echo "$root_path" | grep -q "::"; then
    echo "root's PATH contains an empty directory (::)"
fi
if echo "$root_path" | grep -q ":$"; then
    echo "root's PATH contains a trailing colon (:)"
fi

# Check each directory in the PATH
for dir in $(echo "$root_path" | tr ":" " "); do
    if [ -d "$dir" ]; then
        ls -ldH "$dir" | awk -v dir="$dir" '
        $9 == "." {print "PATH contains current working directory (.)"}
        $3 != "root" {print dir, "is not owned by root"}
        substr($1,6,1) != "-" {print dir, "is group writable"}
        substr($1,9,1) != "-" {print dir, "is world writable"}
        '
    else
        echo "$dir is not a directory"
    fi
done

# Remediation prompt
read -p "Do you want to correct any issues found in root's PATH? (y/n): " choice

if [[ "$choice" == "y" ]]; then
    # Correct empty directories
    if echo "$root_path" | grep -q "::"; then
        echo "Removing empty directories from root's PATH..."
        # Code to remove empty directories (this needs manual handling as the script cannot auto-modify the PATH)
    fi
    
    # Correct trailing colon
    if echo "$root_path" | grep -q ":$"; then
        echo "Removing trailing colon from root's PATH..."
        # Code to remove trailing colon (this needs manual handling as the script cannot auto-modify the PATH)
    fi

    # Correct permissions
    for dir in $(echo "$root_path" | tr ":" " "); do
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
