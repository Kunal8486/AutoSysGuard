#!/bin/bash

SOURCE_DIR=$1
DEST_DIR=$2
COMPRESSION=$3

# Create the destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Check if compression is enabled
if [ "$COMPRESSION" == "compress" ]; then
    TAR_FILE="$DEST_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czvf "$TAR_FILE" -C "$SOURCE_DIR" .
    echo "Backup created with compression at $TAR_FILE"
else
    cp -r "$SOURCE_DIR" "$DEST_DIR"
    echo "Backup created at $DEST_DIR"
fi
