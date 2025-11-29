#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the new file path from the argument
NEW_FILE="$1"

# Standardize .mdc to .md
if [[ "$NEW_FILE" == *.mdc ]]; then
  NEW_FILE_MD="${NEW_FILE%.mdc}.md"
  mv "$NEW_FILE" "$NEW_FILE_MD"
  NEW_FILE="$NEW_FILE_MD"
fi

# Define the path to the index file
INDEX_FILE="/Users/stuart/Desktop/CoachPotato/DevStack/Reference/Docs/index.yaml"
INDEX_DIR=$(dirname "$INDEX_FILE")

# Create the directory for the index file if it doesn't exist
mkdir -p "$INDEX_DIR"

# Create the index file with a header if it doesn't exist
if [ ! -f "$INDEX_FILE" ]; then
  echo "files:" > "$INDEX_FILE"
fi

# Append the new file to the index, checking if it's already there
if ! grep -qF -- "$NEW_FILE" "$INDEX_FILE"; then
  echo "  - $NEW_FILE" >> "$INDEX_FILE"
fi
