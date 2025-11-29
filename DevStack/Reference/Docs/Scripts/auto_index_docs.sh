#!/usr/bin/env bash

DOCS_DIR="../AppleDocs"
INDEX_FILE="$DOCS_DIR/index.yaml"

# Start the index file
cat << EOF > "$INDEX_FILE"
sections:
EOF

# Function to add a section to the index
add_section() {
  local section_id=$1
  local section_name=$2
  local section_dir=$3

  echo "  - id: $section_id" >> "$INDEX_FILE"
  echo "    name: \"$section_name
