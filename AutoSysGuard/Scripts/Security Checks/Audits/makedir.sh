#!/bin/bash

# Read the structure file
structure_file="./Structure.txt"
current_path="."

# Create directories and files based on the structure in the file
while IFS= read -r line; do
    # Determine indentation level (number of leading spaces)
    indent_level=$(echo "$line" | grep -o '^[ ]*' | awk '{print length}')
    # Remove leading spaces
    item=$(echo "$line" | sed 's/^[ \t]*//')

    # Update current path based on indentation
    if [[ $indent_level -gt 0 ]]; then
        # Go to the parent directory for a new indentation level
        current_path="${current_path%/*}"
    fi

    # Check if the item is a directory or a file
    if [[ "$item" == */ ]]; then
        # Create the directory and update current path
        mkdir -p "$current_path/$item"
        current_path="$current_path/$item"
    else
        # Create the file in the current directory
        touch "$current_path/$item"
    fi
done < "$structure_file"

echo "Directory and file structure created from $structure_file."
