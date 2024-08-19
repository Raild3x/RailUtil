#!/bin/bash

set -e

echo "Setting up your environment..."

# Define the directory to clean and the subdirectory to keep
SRC_DIR="src"
KEEP_DIR="$SRC_DIR/RailUtil"

# Check if the source directory exists
if [ ! -d "$SRC_DIR" ]; then
    echo "Error: Source directory $SRC_DIR does not exist."
    exit 1
fi

# Check if the RailUtil directory exists
if [ ! -d "$KEEP_DIR" ]; then
    echo "Error: Keep directory $KEEP_DIR does not exist."
    exit 1
fi

# Find and remove everything in the src directory except the RailUtil directory
echo "Cleaning up directory $SRC_DIR, keeping $KEEP_DIR..."
if ! find "$SRC_DIR" -mindepth 1 -maxdepth 1 ! -path "$KEEP_DIR" -exec rm -rf {} +; then
    echo "Error: Failed to remove files from $SRC_DIR."
    exit 1
fi

# Change directory to the RailUtil directory
if ! cd "$KEEP_DIR"; then
    echo "Error: Failed to change directory to $KEEP_DIR."
    exit 1
fi

# Install the Wally Packages
echo "Installing Wally Package Dependencies..."
if ! wally install; then
    echo "Error: Failed to install Wally packages."
    exit 1
fi

# Move up to original Directory
cd ../..

# Move the Packages directory to the src directory
echo "Moving Packages directory up one level..."
if ! mv src/RailUtil/Packages src/; then
    echo "Error: Failed to move Packages directory."
    exit 1
fi

# Ensure a sourcemap exists
echo "Generating sourcemap..."
if ! rojo sourcemap default.project.json -o sourcemap.json; then
    echo "Error: Failed to generate sourcemap."
    exit 1
fi

# Generate the Wally Package Types
echo "Generating Wally Package Types..."
if ! wally-package-types --sourcemap sourcemap.json src/Packages/; then
    echo "Error: Failed to generate Wally package types."
    exit 1
fi

# Move the generated Wally files out of the Packages dir and into the src dir
echo "Moving Wally Packages to src directory..."
DIR_TO_MOVE="src/Packages"

# Check if the Packages directory exists before moving files
if [ ! -d "$DIR_TO_MOVE" ]; then
    echo "Error: Directory $DIR_TO_MOVE does not exist."
    exit 1
fi

# Move all visible files and directories
if ! mv "$DIR_TO_MOVE"/* "$SRC_DIR" 2>/dev/null; then
    echo "Error: Failed to move visible files from $DIR_TO_MOVE to $SRC_DIR."
    exit 1
fi
echo "Moved visible files."

# Remove the now-empty original directory
echo "Removing original Packages directory..."
if ! rmdir "$DIR_TO_MOVE"; then
    echo "Error: Failed to remove the original Packages directory."
    exit 1
fi

# Ensure a sourcemap exists
echo "Regenerating sourcemap..."
if ! rojo sourcemap default.project.json -o sourcemap.json; then
    echo "Error: Failed to generate sourcemap."
    exit 1
fi

echo "Setup Complete"